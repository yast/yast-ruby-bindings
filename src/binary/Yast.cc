/*---------------------------------------------------------------------\
|                                                                      |
|                      __   __    ____ _____ ____                      |
|                      \ \ / /_ _/ ___|_   _|___ \                     |
|                       \ V / _` \___ \ | |   __) |                    |
|                        | | (_| |___) || |  / __/                     |
|                        |_|\__,_|____/ |_| |_____|                    |
|                                                                      |
|                                                                      |
| ruby language support                              (C) Novell Inc.   |
\----------------------------------------------------------------------/

Author: Duncan Mac-Vicar <dmacvicar@suse.de>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version
2 of the License, or (at your option) any later version.

*/

#include <y2/Y2ComponentCreator.h>

#include <ycp-ui/YUIComponent.h>

#include <y2/Y2ComponentBroker.h>
#include <y2/Y2Namespace.h>
#include <y2/Y2Component.h>
#include <y2/Y2Function.h>

#include <ycp/pathsearch.h>
#include <ycp/y2log.h>
#include <ycp/YExpression.h>
#include <ycp/YCPValue.h>
#include <ycp/YCPCode.h>
#include <ycp/YCPByteblock.h>
#include <ycp/Import.h>
#include <ycp/y2log.h>

#include "ruby.h"

#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"
#include "Y2RubyUtils.h"

/*
 * Ruby module anchors
 *
 */
static VALUE rb_mYast;
static VALUE rb_cYReference;
static VALUE rb_cByteblock;
static VALUE rb_cYCode;

extern "C" {

static Y2Namespace *
getNs (const char * ns_name)
{
  Import import(ns_name);  // has a static cache
  Y2Namespace *ns = import.nameSpace();
  if (ns == NULL)
  {
    y2error ("ruby call: Can't import namespace '%s'", ns_name);
  }
  else
  {
    ns->initialize ();
  }
  return ns;
}


/*
 * import_namespace
 *
 * tries to import a namespace
 * throws a NameError if failed
 *
 */
static VALUE
import_namespace( const char *name)
{
  Y2Namespace *ns = getNs(name);
  if (ns == NULL)
  {
    rb_raise( rb_eNameError, "component cannot import namespace '%s'", name );
    return Qnil;
  }

  y2debug("namespace created from %s\n", ns->filename().c_str());
  return Qtrue;
}


/*
 * import( name )
 *
 * Tries to import a YCP namespace
 *
 * call-seq:
 *   YCP::import("name")
 *
 */

static VALUE
ycp_module_import( VALUE self, VALUE name)
{
  const char *s = StringValuePtr(name);
  return import_namespace(s);
}

static VALUE
ycp_find_include_file( VALUE self, VALUE path)
{
  string ipath (StringValuePtr(path));
  string include_path = YCPPathSearch::find (YCPPathSearch::Include, ipath);
  if (include_path.empty())
    rb_raise(rb_eRuntimeError, "Cannot find client %s", ipath.c_str());

  return yrb_utf8_str_new(include_path);
}
/*
 * ycp_module_each_symbol(namespace) -> iterator
 *
 * iterates all symbols in a namespace and yields the
 * symbol name and category
 *
 * call-seq:
 *   each_symbol("namespace") { |symbol,category| ... }
 *
 */

static VALUE
ycp_module_symbols(VALUE self, VALUE namespace_name)
{
  const char *name = StringValuePtr(namespace_name);
  Y2Namespace *ns = getNs(name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "error getting namespace '%s'", name );
    return Qnil;
  }

  y2debug("got namespace from %s\n", ns->filename().c_str());

  VALUE res = rb_hash_new();
  for (unsigned int i=0; i < ns->symbolCount(); ++i)
  {
    SymbolEntryPtr s = ns->symbolEntry(i);
    VALUE name = yrb_utf8_str_new(s->name());
    VALUE type = ID2SYM(rb_intern(s->catString().c_str()));
    rb_hash_aset(res,name,type);
  }
  return res;
}

/*
 * set the caller location to log properly the Ruby source location,
 * needs to be called before evaluating any YaST function outside Ruby
 */
void set_ruby_source_location(VALUE file, VALUE lineno)
{
  YaST::ee.setFilename(RSTRING_PTR(file));
  YaST::ee.setLinenumber(FIX2INT(lineno));
}

/*
 * call_ycp_function
 *
 * Forwards a ruby call to the namespace
 *
 * First argument is the namespace
 * then function name and arguments
 *
 */

static VALUE
ycp_module_call_ycp_function(int argc, VALUE *argv, VALUE self)
{
  const char *namespace_name = StringValuePtr(argv[0]);
  const char *function_name;
  VALUE symbol = argv[1];

  if (SYMBOL_P(symbol))
    function_name = (const char *)rb_id2name( SYM2ID( symbol ) );
  else
    function_name = StringValuePtr( symbol );

  y2debug("Dynamic Proxy: [%s::%s] with [%d] params\n", namespace_name, function_name, argc);

  Y2Namespace *ns = getNs(namespace_name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "Component cannot import namespace '%s' for symbol '%s'", namespace_name, function_name );
    return Qnil;
  }

  y2debug("Namespace created from %s\n", ns->filename().c_str());

  TableEntry *sym_te = ns->table()->find(function_name);

  if (sym_te == NULL)
  {
    y2internal ("No such symbol %s::%s", namespace_name, function_name);
    rb_raise( rb_eNameError, "YCP symbol '%s' not found in namespace '%s'", function_name, namespace_name );
    return Qnil;
  }

  if (sym_te->sentry ()->isVariable () ||
      sym_te->sentry ()->isReference ())
  {
    y2debug ("Variable or reference %s\n", function_name);
    //get
    if (argc==2)
      return ycpvalue_2_rbvalue(sym_te->sentry()->value());
    // set the variable
    else
    {
      sym_te->sentry()->setValue(rbvalue_2_ycpvalue(argv[2]));
      return argv[2];
    }
  }
  else
  { // no indent yet
    Y2Function* call = ns->createFunctionCall(function_name, 0 /*Type::fromSignature(signature)*/);

    if (call == NULL)
    {
      y2internal ("cannot create function call %s\n", function_name);
      rb_raise( rb_eRuntimeError, "can't create call to %s::%s", namespace_name, function_name);
    }

    y2debug("Call %s", function_name);
    std::map<int,SymbolEntryPtr> refs;
    // add the parameters
    for (int i=4; i < argc; i++)
    {
      YCPValue v = rbvalue_2_ycpvalue(argv[i]);
      y2debug("Append parameter %s", v->toString().c_str());

      const char *class_name = rb_obj_classname(argv[i]);
      //handle args passed by references
      if (!strcmp(class_name, "Yast::ArgRef"))
      {
        refs[i] = v->asReference()->entry();
      }
      call->appendParameter (v);
    }
    call->finishParameters ();

    set_ruby_source_location(argv[2], argv[3]);

    YCPValue res = call->evaluateCall ();
    delete call;
    for (std::map<int,SymbolEntryPtr>::iterator i = refs.begin(); i != refs.end(); ++i)
    {
      //set back reference
      VALUE val = ycpvalue_2_rbvalue(i->second->value());
      RB_GC_GUARD(val);
      rb_funcall(argv[i->first], rb_intern("value="), 1, val);
    }
    return ycpvalue_2_rbvalue(res);
  }
}


/*--------------------------------------------
 *
 * Document-module: Yast
 *
 * The YaST module encloses all Yast related code.
 *
 *--------------------------------------------
 */

//y2_logger_helper

//y2_logger (level, comp, file, line, function, "%s", message);

static VALUE
yast_y2_logger( int argc, VALUE *argv, VALUE self )
{
  Check_Type(argv[0], T_FIXNUM);
  Check_Type(argv[1], T_STRING);
  Check_Type(argv[2], T_STRING);
  Check_Type(argv[3], T_FIXNUM);
  Check_Type(argv[4], T_STRING);

  int i;
  for ( i = 5; i < argc; i++)
  {
    Check_Type(argv[i], T_STRING);
  }
  y2_logger((loglevel_t)FIX2INT(argv[0]),RSTRING_PTR(argv[1]),RSTRING_PTR(argv[2]),FIX2INT(argv[3]),"",RSTRING_PTR(argv[5]));
  return Qnil;
}

/*--------------------------------------------
 * Document-method: add_module_path(path)
 * call-seq:
 *   Yast.add_module_path([String]) -> nil
 *
 * Adds path to module search path. Useful to test modules from specific directory.
 *
 * For testing recomended way is to set properly Y2DIR ENV.
 */
static VALUE add_module_path( VALUE self, VALUE path )
{
  y2debug ("add module path %s", RSTRING_PTR(path));
  YCPPathSearch::addPath (YCPPathSearch::Module, RSTRING_PTR(path));
  return Qnil;
}

/*
 * Adds path to include search path. Useful to test includes from specific directory.
 * For testing recomended way is to set properly Y2DIR ENV.
 */
static VALUE
add_include_path( VALUE self, VALUE path )
{
  y2debug ("add include path %s", RSTRING_PTR(path));
  YCPPathSearch::addPath (YCPPathSearch::Include, RSTRING_PTR(path));
  return Qnil;
}

static VALUE
y2dir_paths( VALUE self )
{
  int size = Y2PathSearch::numberOfComponentLevels();
  VALUE result = rb_ary_new2(size);
  for (int i = 0; i < size; ++i)
  {
    rb_ary_push(result, yrb_utf8_str_new(Y2PathSearch::searchPath(Y2PathSearch::GENERIC,i)));
  }
  return result;
}

static VALUE byteblock_to_s(VALUE self)
{
  YCPByteblock *bb;
  Data_Get_Struct(self, YCPByteblock, bb);

  if (bb)
    return yrb_utf8_str_new((*bb)->toString());
  else
    rb_raise(rb_eRuntimeError, "Byteblock is empty");

}

static VALUE ref_call( int argc, VALUE *argv, VALUE self )
{
  SymbolEntry *se;
  Data_Get_Struct(self, SymbolEntry, se);
  if (se->isFunction())
  {
    Y2Function* call = ((Y2Namespace*)(se->nameSpace()))->createFunctionCall(se->name(), se->type());
    // add the parameters
    for (int i=0; i < argc; i++)
    {
      YCPValue v = rbvalue_2_ycpvalue(argv[i]);
      call->appendParameter (v);
    }
    call->finishParameters ();

    YCPValue res = call->evaluateCall ();
    delete call;
    return ycpvalue_2_rbvalue(res);
  }
  else
  {
    rb_raise(rb_eRuntimeError, "Unknown ref type %s", se->toString().c_str());
  }
  return Qnil;
}

static VALUE code_call( int argc, VALUE *argv, VALUE self )
{
  YCPCode *yc;
  Data_Get_Struct(self, YCPCode, yc);
  if (yc)
    return ycpvalue_2_rbvalue((*yc)->evaluate());
  else
    rb_raise(rb_eRuntimeError, "YCode is empty");
}

static void init_ui()
{
  const char *ui_name = "ncurses";

  Y2Component *c = YUIComponent::uiComponent();
  if (c == 0)
  {
    y2debug ("UI component not created yet, creating %s", ui_name);

    c = Y2ComponentBroker::createServer(ui_name); // just dummy ui if none is defined
    if (c == 0)
    {
      y2error("can't create UI component");
      return;
    }

    c->setServerOptions(0, NULL);
  }
  else
  {
    y2debug("UI component already present: %s", c->name ().c_str ());
  }
}

} //extern C

extern "C"
{
  /*
   * Ruby module initializer
   *
   * "require 'ycpx'" will call Init_ycpx()
   */

  void
  Init_yastx()
  {
    YCPPathSearch::initialize();
    init_ui();

    /*
     * module YCP
     */
    rb_mYast = rb_define_module("Yast");
    rb_define_singleton_method( rb_mYast, "import_pure", RUBY_METHOD_FUNC(ycp_module_import), 1);
    rb_define_singleton_method( rb_mYast, "find_include_file", RUBY_METHOD_FUNC(ycp_find_include_file), 1);

    rb_define_singleton_method( rb_mYast, "call_yast_function", RUBY_METHOD_FUNC(ycp_module_call_ycp_function), -1);

    rb_define_singleton_method( rb_mYast, "symbols", RUBY_METHOD_FUNC(ycp_module_symbols), 1);
    rb_define_singleton_method( rb_mYast, "add_module_path", RUBY_METHOD_FUNC(add_module_path), 1);
    rb_define_singleton_method( rb_mYast, "add_include_path", RUBY_METHOD_FUNC(add_include_path), 1);
    rb_define_singleton_method( rb_mYast, "y2paths", RUBY_METHOD_FUNC(y2dir_paths), 0);

    rb_define_method( rb_mYast, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);
    rb_define_singleton_method( rb_mYast, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);

    // Y2 references
    rb_cYReference = rb_define_class_under(rb_mYast, "YReference", rb_cObject);
    rb_define_method(rb_cYReference, "call", RUBY_METHOD_FUNC(ref_call), -1);

    // Y2 code
    rb_cYCode = rb_define_class_under(rb_mYast, "YCode", rb_cObject);
    rb_define_method(rb_cYCode, "call", RUBY_METHOD_FUNC(code_call), -1);

    //Byteblock
    rb_cByteblock = rb_define_class_under(rb_mYast, "Byteblock", rb_cObject);
    rb_define_method(rb_cByteblock, "to_s", RUBY_METHOD_FUNC(byteblock_to_s), 0);
  }
}
