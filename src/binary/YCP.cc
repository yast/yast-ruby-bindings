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
#include <wfm/Y2WFMComponent.h>
#include <wfm/WFM.h>

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

//#include "YRuby.h"
#include "RubyLogger.h"
#include "Y2RubyTypeTerm.h"
#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"
#include "YRuby.h"

//forward declaration
extern "C" YCPValue _call_ycp_builtin ( const string &module_name, const string &func_name, int argc, VALUE *argv );

// make the compiler happy when
// calling rb_define_method()
typedef VALUE (ruby_method)(...);
// more useful macros
#define RB_FINALIZER(func) ((void (*)(...))func)

#define GetY2Object(obj, po) \
    Data_Get_Struct(obj, Y2Namespace, po)

/*
 * Ruby module anchors
 *
 */
static VALUE rb_mYaST;
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
    y2error ("zero or one arguments required (ui name, default %s", ui_name);
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


/*--------------------------------------------
 * 
 * Document-module: YCP
 * 
 * The YCP module gives access to primitives of the YCP language.
 * 
 * Its here for completeness, you're mostly better off using Ruby library functions.
 * 
 *--------------------------------------------
 */



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
  y2internal("component name %s\n", c->name().c_str());
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
  else
  {
    y2internal("namespace created from %s\n", ns->filename().c_str());
  }
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
  else
  {
    y2internal("got namespace from %s\n", ns->filename().c_str());
  }

  for (unsigned int i=0; i < ns->symbolCount(); ++i)
  {
    SymbolEntryPtr s = ns->symbolEntry(i);
    VALUE arr = rb_ary_new();
    rb_ary_push(arr, rb_str_new2(s->name()));
    rb_ary_push(arr, ID2SYM(rb_intern(s->catString().c_str())));
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
  y2internal("Dynamic Proxy: [%d] params\n", argc);
  const char *namespace_name = StringValuePtr(argv[0]);
  const char *function_name;
  VALUE symbol = argv[1];

  if (SYMBOL_P(symbol)) 
    function_name = (const char *)rb_id2name( SYM2ID( symbol ) );
  else
    function_name = StringValuePtr( symbol );
  
  y2internal("Dynamic Proxy: [%s::%s] with [%d] params\n", namespace_name, function_name, argc);

  //Data_Get_Struct( self, class Y2Namespace, ns );
  //ns = gNameSpaces[self];

  // get the name of the module
  //VALUE namespace_name = rb_funcall(self, rb_intern("name"), 0);

  lookup_namespace_component(namespace_name);

  // import the namespace
  //Y2Namespace *ns = c->import(namespace_name);
  Y2Namespace *ns = getNs(namespace_name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "Component cannot import namespace '%s' for symbol '%s'", namespace_name, function_name );
    return Qnil;
  }
  else
  {
    y2internal("Namespace created from %s\n", ns->filename().c_str());
  }

  y2internal("Namespace %s initialized\n", namespace_name);

  TableEntry *sym_te = ns->table()->find(function_name);

  if (sym_te == NULL)
  {
    y2error ("No such symbol %s::%s", namespace_name, function_name);
    rb_raise( rb_eNameError, "YCP symbol '%s' not found in namespace '%s'", function_name, namespace_name );
    return Qnil;
  }

  if (sym_te->sentry ()->isVariable () ||
      sym_te->sentry ()->isReference ())
  {
    y2internal ("Variable or reference %s\n", function_name);
    // set the variable
    //ret_yv = YCP_getset_variable (aTHX_ ns_name, sym_te->sentry (), args);
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
  return Qnil;
}


/*
 * helper for call_ycp_builtin
 * 
 */

YCPValue
_call_ycp_builtin ( const string &module_name, const string &func_name, int argc, VALUE *argv )
{
  // access directly the statically declared builtins
  extern StaticDeclaration static_declarations;

  string qualified_name_s = module_name + "::" + func_name;
  const char *qualified_name = qualified_name_s.c_str ();

  y2milestone("qualified name '%s', %d args", qualified_name, argc);
  
  declaration_t *bi_dt = static_declarations.findDeclaration (qualified_name);
  if (bi_dt == NULL)
  {
    y2error ("no such builtin '%s'", qualified_name);
    rb_raise( rb_eRuntimeError, "no YCP builtin '%s'", qualified_name);
    return YCPNull ();
  }
  y2milestone("builtin '%s' found.", module_name.c_str());
  // construct a builtin call using the proper overloaded builtin
  YEBuiltin *bi_call = new YEBuiltin(bi_dt);

  // attach the parameters:

  // we would like to know the destination type so that we could
  // convert eg a Ruby scalar to a YCP symbol, but because the
  // builtins may be overloaded, let's say we want Any
  // maybe a special exceptional hack to make Path for the 1st argument?
  // go through the actual parameters
  int j;
  for (j = 0; j < argc; ++j)
  {
    // convert the value according to the expected type:
    constTypePtr param_tp = (j == 0)? Type::Path : Type::Any;

    YCPValue param_v = rbvalue_2_ycpvalue(argv[j] /*, param_tp */);

    if (param_v.isNull ())
    {
      // an error has already been reported, now refine it.
      // Can't know parameter name?
      y2error ("... when passing parameter #%u to builtin %s",
        j, qualified_name);
      return YCPNull ();
    }
    // Such YConsts without a specific type produce invalid
    // bytecode. (Which is OK here)
    // The actual parameter's YCode becomes owned by the function call?
    YConst *param_c = new YConst (YCode::ycConstant, param_v);
    // for attaching the parameter, must get the real type so that it matches
    constTypePtr act_param_tp = Type::vt2type (param_v->valuetype ());
    // Attach the parameter
    // Returns NULL if OK, Type::Error if excessive argument
    // Other errors (bad code, bad type) shouldn't happen
    constTypePtr err_tp = bi_call->attachParameter (param_c, act_param_tp);
    if (err_tp != NULL)
    {
        if (err_tp->isError ())
        {
          // TODO really need to know the place in Ruby code
          // where we were called from.
          y2error ("Excessive parameter to builtin %s", qualified_name);
        }
        else
        {
          y2internal ("attachParameter returned %s", err_tp->toString ().c_str ());
        }
        return YCPNull ();
    }
  } // for each actual parameter

  // now must check if we got fewer parameters than needed
  // or there was another error while resolving the overload
  constTypePtr err_tp = bi_call->finalize (RubyLogger::instance ());
  if (err_tp != NULL)
  {
    // apparently the error was already reported?
    y2error ("Error type %s when finalizing builtin %s",
    err_tp->toString ().c_str (), qualified_name);
    return YCPNull ();
  }

  // go call it now!
  y2debug ("Ruby is calling builtin %s", qualified_name);
  YCPValue ret_yv = bi_call->evaluate (false /* no const subexpr elim */);
  delete bi_call;

  return ret_yv;
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
  y2_logger((loglevel_t)NUM2INT(argv[0]),RSTRING_PTR(argv[1]),RSTRING_PTR(argv[2]),NUM2INT(argv[3]),"",RSTRING_PTR(argv[5]));
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
    if (!WFM::registered)
    {
      y2milestone("WFM not registered (so what?!)");
    }

    YCPPathSearch::initialize();

    /*
     * Debug: log search pathes
     */
    for ( list<string>::const_iterator it = YCPPathSearch::searchListBegin (YCPPathSearch::Module);
	  it != YCPPathSearch::searchListEnd (YCPPathSearch::Module) ; ++it )
    {
      y2internal("search path %s\n", (*it).c_str() );
    }

    /*
     * module YCP
     */
    rb_mYCP = rb_define_module("YCP");
    rb_define_singleton_method( rb_mYCP, "import_pure", RUBY_METHOD_FUNC(ycp_module_import), 1);
    rb_define_singleton_method( rb_mYCP, "call_ycp_function", RUBY_METHOD_FUNC(ycp_module_call_ycp_function), -1);

    rb_define_singleton_method( rb_mYCP, "each_symbol", RUBY_METHOD_FUNC(ycp_module_each_symbol), 1);

    /*
     * module YCP::Ui
     */
    rb_mUi = rb_define_module_under(rb_mYCP, "Ui");
    rb_define_singleton_method( rb_mUi, "init", RUBY_METHOD_FUNC(ui_init), -1);

    /*
     * module YaST
     */
    rb_mYaST = rb_define_module("YaST");
    rb_define_method( rb_mYaST, "logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);

    y2internal("ryast_term_init\n");
    ryast_term_init(rb_mYaST);

    y2internal("Init_ycpx done\n");
  }
}
