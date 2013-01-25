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
#include <ycp/Import.h>
#include <ycp/y2log.h>

#include "ruby.h"

#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"

/*
 * Ruby module anchors
 *
 */
static VALUE rb_mUi;
static VALUE rb_mYCP;


static Y2Component *owned_uic = 0;

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


/*--------------------------------------------
 *
 * Document-module: YCP::Ui
 *
 *--------------------------------------------
 */

/*
 * ui_init()
 *
 * Load and initialize UI component
 *
 * call-seq:
 *   Ui::init( name = "ncurses" )
 *
 */

static VALUE
ui_init( int argc, VALUE *argv, VALUE self )
{
  const char *ui_name = "ncurses";

  if (argc == 1)
  {
    ui_name = StringValuePtr(argv[0]);
  }
  else if (argc != 0)
  {
    y2internal ("zero or one arguments required (ui name, default %s", ui_name);
    return Qnil;
  }

  Y2Component *c = YUIComponent::uiComponent ();
  if (c == 0)
  {
    y2debug ("UI component not created yet, creating %s", ui_name);

    c = Y2ComponentBroker::createServer (ui_name);
    if (c == 0)
    {
      y2error ("can't create component %s", ui_name);
      return Qnil;
    }

    if (YUIComponent::uiComponent () == 0)
    {
      y2error ("component %s is not a UI", ui_name);
      return Qnil;
    }
    else
    {
      // got it - initialize, remember
      c->setServerOptions (0, NULL);
      owned_uic = c;
    }
  }
  else
  {
    y2debug ("UI component already present: %s", c->name ().c_str ());
  }
  return Qnil;
}


/*
 * Helper
 *
 * lookup_namespace_component()
 *
 * looks a component for a namespace
 * throws RuntimeError is namespace cannot be found
 *
 */

static void
lookup_namespace_component(const char *name)
{
  Y2Component *c = Y2ComponentBroker::getNamespaceComponent(name);
  if (c == NULL)
  {
    y2internal("no component can provide namespace '%s'\n", name);
    rb_raise( rb_eRuntimeError, "no YaST component can provide namespace '%s'", name);
  }
  y2debug("component name %s\n", c->name().c_str());
  return;
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
  lookup_namespace_component(s); /* throws if not found */
  return import_namespace(s);
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
ycp_module_each_symbol(VALUE self, VALUE namespace_name)
{
  const char *name = StringValuePtr(namespace_name);
  Y2Namespace *ns = getNs(name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "error getting namespace '%s'", name );
    return Qnil;
  }

  y2debug("got namespace from %s\n", ns->filename().c_str());

  for (unsigned int i=0; i < ns->symbolCount(); ++i)
  {
    SymbolEntryPtr s = ns->symbolEntry(i);
    VALUE name = rb_str_new2(s->name());
    VALUE type = ID2SYM(rb_intern(s->catString().c_str()));
    VALUE arr = rb_ary_new3(2,name,type);
    rb_yield(arr);
  }
  return Qnil;
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

  lookup_namespace_component(namespace_name);

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
    Y2Function* call = ns->createFunctionCall(function_name, 0 /*Type::fromSignature("list<string>()")*/);

    if (call == NULL)
    {
      y2internal ("cannot create function call %s\n", function_name);
      rb_raise( rb_eRuntimeError, "can't create call to %s::%s", namespace_name, function_name);
    }

    // add the parameters
    for (int i=2; i < argc; i++)
    {
      YCPValue v = rbvalue_2_ycpvalue(argv[i]);
      call->appendParameter (v);
    }
    call->finishParameters ();

    YCPValue res = call->evaluateCall ();
    delete call;
    y2internal ("call succeded\n");
    //y2internal ("Result: %i\n", res->asList()->size());
    return ycpvalue_2_rbvalue(res);
  }
}


/*--------------------------------------------
 *
 * Document-module: YaST
 *
 * The YaST module gives access to the YaST infrastructure, mostly implemented in the YCP language.
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

static VALUE
add_module_path( VALUE self, VALUE path )
{
  y2milestone ("add module path %s", RSTRING_PTR(path));
  YCPPathSearch::addPath (YCPPathSearch::Module, RSTRING_PTR(path));
  return Qnil;
}

static VALUE
add_include_path( VALUE self, VALUE path )
{
  y2milestone ("add include path %s", RSTRING_PTR(path));
  YCPPathSearch::addPath (YCPPathSearch::Include, RSTRING_PTR(path));
  return Qnil;
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
  Init_ycpx()
  {
    YCPPathSearch::initialize();

    /*
     * module YCP
     */
    rb_mYCP = rb_define_module("YCP");
    rb_define_singleton_method( rb_mYCP, "import_pure", RUBY_METHOD_FUNC(ycp_module_import), 1);

    rb_define_singleton_method( rb_mYCP, "call_ycp_function", RUBY_METHOD_FUNC(ycp_module_call_ycp_function), -1);

    rb_define_singleton_method( rb_mYCP, "each_symbol", RUBY_METHOD_FUNC(ycp_module_each_symbol), 1);
    rb_define_singleton_method( rb_mYCP, "add_module_path", RUBY_METHOD_FUNC(add_module_path), 1);
    rb_define_singleton_method( rb_mYCP, "add_include_path", RUBY_METHOD_FUNC(add_include_path), 1);

    rb_define_method( rb_mYCP, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);
    rb_define_singleton_method( rb_mYCP, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);

    /*
     * module YCP::Ui
     */
    rb_mUi = rb_define_module_under(rb_mYCP, "Ui");
    rb_define_singleton_method( rb_mUi, "init", RUBY_METHOD_FUNC(ui_init), -1);
  }
}
