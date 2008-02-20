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

#include <y2/Y2ComponentBroker.h>
#include <y2/Y2Namespace.h>
#include <y2/Y2Component.h>
#include <y2/Y2Function.h>

#include <ycp/pathsearch.h>
#include <ycp/y2log.h>
#include <ycp/YBlock.h>
#include <ycp/YExpression.h>
#include <ycp/YStatement.h>
#include <ycp/YCPValue.h>
#include <ycp/YCPBoolean.h>
#include <ycp/YCPList.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPString.h>
#include <ycp/YCPInteger.h>
#include <ycp/YCPFloat.h>
#include <ycp/YCPElement.h>
#include <ycp/Import.h>
#include <ycp/y2log.h>

#include "ruby.h"

//#include "YRuby.h"
#include "RubyLogger.h"
#include "Y2RubyTypePath.h"
#include "Y2RubyTypeTerm.h"
#include "Y2RubyTypeConv.h"
#include "YRuby.h"

#define GetY2Object(obj, po) \
    Data_Get_Struct(obj, Y2Namespace, po)

static VALUE rb_mYaST;
static VALUE rb_mUi;
static VALUE rb_mYCP;

// make the compiler happy when
// calling rb_define_method()
typedef VALUE (ruby_method)(...);

// more useful macros
#define RB_FINALIZER(func) ((void (*)(...))func)

// this macro saves us from typing
// (ruby_method*) & method_name
// in rb_define_method
#define RB_METHOD(func) ((VALUE (*)(...))func)

Y2Component *owned_uic = 0;
Y2Component *owned_wfmc = 0;

static
Y2Namespace *
getNs (const char * ns_name)
{
  Import import(ns_name);  // has a static cache
  Y2Namespace *ns = import.nameSpace();
  if (ns == NULL)
  {
    y2error ("Ruby call: Can't import namespace '%s'", ns_name);
  }
  else
  {
    ns->initialize ();
  }
  return ns;
}

void init_wfm()
{
    y2milestone("init_wfm");
//     if (Y2WFMComponent::instance () == 0)
//     {
      y2milestone("WFM init");
      owned_wfmc = Y2ComponentBroker::createClient ("wfm");
      if (owned_wfmc == 0)
      {
          y2error ("Cannot create WFM component");
      }
//     }
}

static VALUE
rb_init_ui( int argc, VALUE *argv, VALUE self )
{
  const char *ui_name = "ncurses";

  if (argc == 1)
  {
    Check_Type(argv[0], T_STRING);
    ui_name = RSTRING(argv[0])->ptr;
  }
  else if (argc != 0)
  {
    y2error ("Zero or one arguments required (ui name, default %s", ui_name);
    return Qnil;
  }

  Y2Component *c = YUIComponent::uiComponent ();
  if (c == 0)
  {
    y2debug ("UI component not created yet, creating %s", ui_name);

    c = Y2ComponentBroker::createServer (ui_name);
    if (c == 0)
    {
      y2error ("Cannot create component %s", ui_name);
      return Qnil;
    }

    if (YUIComponent::uiComponent () == 0)
    {
      y2error ("Component %s is not a UI", ui_name);
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

typedef struct brokerinfo
{
  Y2Component *component;
  Y2Namespace *ns;
}
BrokerInfo;

//  mark for garbage collection
// NOT USED, ONLY WHEN USING DATA_WRAP_STRUCT
void
yast_module_mark( BrokerInfo *info )
{}

// dispose a namespace
// NOT USED, ONLY WHEN USING DATA_WRAP_STRUCT
void
yast_module_free( BrokerInfo *info )
{
  //std::cout << "Deleting namespace." << std::endl;
  //delete info;
}

VALUE
yast_module_allocate( VALUE klass )
{
  BrokerInfo *info = new BrokerInfo;
  return Data_Wrap_Struct( klass, yast_module_mark, RB_FINALIZER(yast_module_free), info );
}

VALUE
yast_module_initialize( VALUE self, VALUE param_ns_name )
{
  Check_Type(param_ns_name, T_STRING);
  rb_iv_set(self, "@namespace_name", param_ns_name);
  init_wfm();
  return self;
}


VALUE
yast_module_name( VALUE self )
{
  return rb_iv_get(self, "@namespace_name");
}

VALUE
yast_module_methods( VALUE self )
{
  return Qnil;
}

//forward declaration
YCPValue ycp_call_builtin ( const string &module_name, const string &func_name, int argc, VALUE *argv );

/**
 * looks a component for a namespace
 * throws
 */
static VALUE
ycp_module_lookup_namespace_component(VALUE self, VALUE name)
{
  Y2Component *c;
  c = Y2ComponentBroker::getNamespaceComponent(RSTRING(name)->ptr);
  if (c == NULL)
  {
    y2internal("No component can provide namespace %s\n", RSTRING (name)->ptr);
    rb_raise( rb_eRuntimeError, "No YaST component can provide namespace %s\n", RSTRING (name)->ptr);
  }
  y2internal("component name %s\n", c->name().c_str());
  return Qtrue;
}

/*
 tries to import a namespace and throws a NameError if
 failed
*/
static VALUE
ycp_module_import_namespace( VALUE self, VALUE namespace_name)
{
  Y2Namespace *ns = getNs( RSTRING (namespace_name)->ptr);
  if (ns == NULL)
  {
    rb_raise( rb_eNameError, "Component cannot import namespace '%s'", RSTRING (namespace_name)->ptr);
    return Qnil;
  }
  else
  {
    y2internal("Namespace created from %s\n", ns->filename().c_str());
  }
  return Qtrue;
}

static VALUE
ycp_module_import( VALUE self, VALUE name)
{
  ycp_module_lookup_namespace_component(self,name);
  return ycp_module_import_namespace(self,name);
}

/**
 * iterates all symbols in a namespace and yields the
 * symbol name and category
 */
VALUE
ycp_module_each_symbol(VALUE self, VALUE namespace_name)
{
  Y2Namespace *ns = getNs( RSTRING (namespace_name)->ptr);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "Error getting namespace '%s'", RSTRING (namespace_name)->ptr );
    return Qnil;
  }
  else
  {
    y2internal("Got namespace from %s\n", ns->filename().c_str());
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

/**
 * Forwards a ruby call to the namespace
 * First argument is the namespace
 * then function name and arguments
 */
VALUE
ycp_module_forward_call(int argc, VALUE *argv, VALUE self)
{
  y2internal("Dynamic Proxy: [%d] params\n", argc);
  VALUE symbol = argv[1];
  VALUE namespace_name = argv[0];

  // the func name (1st argument, is a symbol
  // lets convert it to string
  VALUE symbol_str = rb_funcall(symbol, rb_intern("to_s"), 0);
  y2internal("Dynamic Proxy: [%s::%s] with [%d] params\n", RSTRING(namespace_name)->ptr, RSTRING(symbol_str)->ptr, argc);

  //Check_Type(argv[0], T_STRING);
  //y2internal(RSTRING (symbol)->ptr);
  //Data_Get_Struct( self, class Y2Namespace, ns );
  //ns = gNameSpaces[self];

  // get the name of the module
  //VALUE namespace_name = rb_funcall(self, rb_intern("name"), 0);
  

  // SCR
  // this is a hack before the builtin namespaces get a uniform interface:
  if (! strcmp (RSTRING (namespace_name)->ptr, "SCR"))
  {
    y2internal("Dynamic Proxy: [%s::%s] is a call to SCR\n", RSTRING(namespace_name)->ptr, RSTRING(symbol_str)->ptr);
    YCPValue res;
    res = ycp_call_builtin( RSTRING(namespace_name)->ptr, RSTRING(symbol_str)->ptr, argc, argv);
    return ycpvalue_2_rbvalue(res);
    //return Qnil;
  }

  ycp_module_lookup_namespace_component(self, namespace_name);

  // import the namespace
  //Y2Namespace *ns = c->import(RSTRING (namespace_name)->ptr);
  Y2Namespace *ns = getNs( RSTRING (namespace_name)->ptr);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "Component cannot import namespace '%s' for symbol '%s'", RSTRING (namespace_name)->ptr, RSTRING(symbol_str)->ptr );
    return Qnil;
  }
  else
  {
    y2internal("Namespace created from %s\n", ns->filename().c_str());
  }

  y2internal("Namespace %s initialized\n", RSTRING (namespace_name)->ptr);

  TableEntry *sym_te = ns->table()->find (RSTRING(symbol_str)->ptr);

  if (sym_te == NULL)
  {
    y2error ("No such symbol %s::%s", RSTRING (namespace_name)->ptr, RSTRING(symbol_str)->ptr);
    rb_raise( rb_eNameError, "YCP symbol '%s' not found in namespace '%s'", RSTRING(symbol_str)->ptr, RSTRING (namespace_name)->ptr );
    return Qnil;
  }

  if (sym_te->sentry ()->isVariable () ||
      sym_te->sentry ()->isReference ())
  {
    y2internal ("Variable or reference %s\n", RSTRING(symbol_str)->ptr);
    // set the variable
    //ret_yv = YCP_getset_variable (aTHX_ ns_name, sym_te->sentry (), args);
  }
  else
  { // no indent yet
    Y2Function* call = ns->createFunctionCall (RSTRING(symbol_str)->ptr, 0 /*Type::fromSignature("list<string>()")*/);

    if (call == NULL)
    {
      y2internal ("Cannot create function call %s\n", RSTRING(symbol_str)->ptr);
      rb_raise( rb_eRuntimeError, "Can't create call to %s::%s", RSTRING (namespace_name)->ptr, RSTRING(symbol_str)->ptr);
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
    y2internal ("Call succeded\n");
    //y2internal ("Result: %i\n", res->asList()->size());
    return ycpvalue_2_rbvalue(res);
  }
  return Qnil;
}

YCPValue ycp_call_builtin ( const string &module_name, const string &func_name, int argc, VALUE *argv )
{
  // access directly the statically declared builtins
  extern StaticDeclaration static_declarations;
  string qualified_name_s = module_name + "::" + func_name;
  const char *qualified_name = qualified_name_s.c_str ();

  y2milestone("Qualified name '%s'", qualified_name);
  /*
    this does not work across namespaces
      TableEntry *bi_te = static_declarations.symbolTable ()->find (qualified_name);
      if (bi_te == NULL)
      {
    y2error ("No such builtin %s",qualified_name);
    return YCPNull ();
      }
  
      SymbolEntry *bi_se = bi_te->sentry ();
      assert (bi_se != NULL);
      assert (bi_se->isBuiltin ());
      declaration_t bi_dt = bi_se->declaration ();
  */
  declaration_t *bi_dt = static_declarations.findDeclaration (qualified_name);
  if (bi_dt == NULL)
  {
    y2error ("No such builtin '%s'", qualified_name);
    return YCPNull ();
  }
  y2milestone("builtin '%s' found.", module_name.c_str());
  // construct a builtin call using the proper overloaded builtin
  YEBuiltin *bi_call = new YEBuiltin (bi_dt);

  // attach the parameters:

  // we would like to know the destination type so that we could
  // convert eg a Ruby scalar to a YCP symbol, but because the
  // builtins may be overloaded, let's say we want Any

  // maybe a special exceptional hack to make Path for the 1st argument?

  // go through the actual parameters
  int j;
  for (j = 1; j < argc; ++j)
  {
    y2milestone("builtin param '%d'", j-1);
    // convert the value according to the expected type:
    constTypePtr param_tp = (j == 0)? Type::Path : Type::Any;
    y2milestone("builtin param '%d' 1", j-1);
    
    // convert the first argument to a path
    YCPValue param_v;
    if ( j == 1 )
      param_v = rbvalue_2_ycppath(argv[j]);
    else
      param_v = rbvalue_2_ycpvalue(argv[j] /*, param_tp */);
    
    y2milestone("builtin param '%d' 2", j-1);
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



//y2_logger_helper

//y2_logger (level, comp, file, line, function, "%s", message);

static VALUE
rb_y2_logger( int argc, VALUE *argv, VALUE self )
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
  y2_logger((loglevel_t)NUM2INT(argv[0]),RSTRING(argv[1])->ptr,RSTRING(argv[2])->ptr,NUM2INT(argv[3]),"",RSTRING(argv[5])->ptr);
  return Qnil;
}

extern "C"
{
  void
  Init_yastx()
  {
    YCPPathSearch::initialize ();

    for ( list<string>::const_iterator it = YCPPathSearch::searchListBegin (YCPPathSearch::Module); it != YCPPathSearch::searchListEnd (YCPPathSearch::Module) ; ++it )
    {
      y2internal("%s\n", (*it).c_str() );
    }

    rb_mYaST = rb_define_module("YaST");

    //rb_mYCP = rb_define_module_under(rb_mYaST, "YCP");
    rb_mYCP = rb_define_module("YCP");
    rb_define_singleton_method( rb_mYCP, "import", RB_METHOD(ycp_module_import), 1);
    rb_define_singleton_method( rb_mYCP, "forward_call", RB_METHOD(ycp_module_forward_call), -1);
    rb_define_singleton_method( rb_mYCP, "each_symbol", RB_METHOD(ycp_module_each_symbol), 1);

    rb_mUi = rb_define_module_under(rb_mYCP, "Ui");
    rb_define_singleton_method( rb_mUi, "init", RB_METHOD(rb_init_ui), -1);
    
    rb_define_method( rb_mYaST, "y2_logger", RB_METHOD(rb_y2_logger), -1);

    ryast_path_init(rb_mYaST);
    ryast_term_init(rb_mYaST);
  }
}
