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

#include "YRubyNamespace.h"

// Ruby stuff
#include <ruby.h>

#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>

#include <ycp/YCPElement.h>
#include <ycp/Type.h>
#include <ycp/YCPVoid.h>
#include <stdio.h>

#include "YRuby.h"
#include "Y2RubyUtils.h"

/**
 * The definition of a function that is implemented in Ruby
 */
class Y2RubyFunction : public Y2Function
{
  //! module name
  string m_module_name;
  //! function name, excluding module name
  string m_local_name;
  //! function type
  constFunctionTypePtr m_type;
  //! data prepared for the inner call
  YCPList m_call;

public:
  Y2RubyFunction (const string &module_name,
                  const string &local_name,
                  constFunctionTypePtr function_type
                 ) :
      m_module_name (module_name),
      m_local_name (local_name),
      m_type (function_type)
  {}

  //! called by YEFunction::evaluate
  YCPValue evaluateCall ()
  {
    return YRuby::yRuby()->callInner ( m_module_name,
                                       m_local_name,
                                       m_call,
                                       m_type->returnType() );
  }
  /**
  * Attaches a parameter to a given position to the call.
  * @return false if there was a type mismatch
  */
  bool attachParameter (const YCPValue& arg, const int position)
  {
    m_call->set (position, arg);
    return true;
  }

  /**
   * What type is expected for the next appendParameter (val) ?
   * (Used when calling from Ruby, to be able to convert from the
   * simple type system of Ruby to the elaborate type system of YCP)
   * @return Type::Any if number of parameters exceeded
   */
  constTypePtr wantedParameterType () const
  {
    int params_so_far = m_call->size ();
    return m_type->parameterType (params_so_far);
  }

  /**
   * Appends a parameter to the call.
   * @return false if there was a type mismatch
   */
  bool appendParameter (const YCPValue& arg)
  {
    y2debug("Adding parameter to function %s::%s of type %s", m_module_name.c_str(), m_local_name.c_str(), arg->valuetype_str());
    m_call->add (arg);
    return true;
  }

  /**
   * Signal that we're done adding parameters.
   * @return false if there was a parameter missing
   */
  bool finishParameters ()
  {
    return true;
  }


  bool reset ()
  {
    m_call = YCPList ();
    return true;
  }

  /**
   * Something for remote namespaces
   */
  string name () const
  {
    return m_local_name;
  }
};

//class that allow us to simulate variable and in fact call ruby accessors
class VariableSymbolEntry : public SymbolEntry
{
private:
  const string &module_name;
public:
  //not so nice constructor that allow us to hook to symbol entry variable reading
  VariableSymbolEntry(const string &r_module_name, const Y2Namespace* name_space, unsigned int position, const char *name, constTypePtr type) :
   SymbolEntry(name_space, position, name, SymbolEntry::c_variable, type),module_name(r_module_name)    {}

  YCPValue setValue (YCPValue value)
  {
    YCPList l;
    l.add(value);
    string method_name = name();
    method_name += "=";
    return YRuby::yRuby()->callInner ( module_name,
      method_name,
      l,
      type()
    );
  }

  YCPValue value () const
  {
    return YRuby::yRuby()->callInner ( module_name,
      name(),
      YCPList(),
      type()
    );
  }

};

void YRubyNamespace::constructSymbolTable(VALUE module)
{
  int offset = 0; //track number of added method, so we can add extra one at the end
  VALUE module_class = rb_obj_class(module);
  //detect if module use new approach for exporting methods or old one
  if (rb_respond_to(module_class, rb_intern("published_methods" )))
  {
    offset = addMethodsNewWay(module_class);
    offset = addVariables(module_class, offset);
  }
  else
  {
    offset = addMethodsOldWay(module);
  }
  addExceptionMethod(module,offset);
  y2debug("%s", symbolsToString().c_str());
}


YRubyNamespace::YRubyNamespace (string name)
    : m_name (name)
{
  y2debug("Creating namespace for '%s'", name.c_str());

  VALUE module = getRubyModule();
  if (module == Qnil)
  {
    y2internal ("The Ruby module '%s' is not provided by its rb file", name.c_str());
    return;
  }

  constructSymbolTable(module);
}

YRubyNamespace::~YRubyNamespace ()
{}

const string YRubyNamespace::filename () const
{
  // TODO improve
  return ".../" + m_name;
}

// this is for error reporting only?
string YRubyNamespace::toString () const
{
  y2error ("TODO");
  return "{\n"
         "/* this namespace is provided in Ruby */\n"
         "}\n";
}

// called when running and the import statement is encountered
// does initialization of variables
// constructor is handled separately after this
YCPValue YRubyNamespace::evaluate (bool cse)
{
  // so we don't need to do anything
  y2debug ("Doing nothing");
  return YCPNull ();
}

Y2Function* YRubyNamespace::createFunctionCall (const string name, constFunctionTypePtr required_type)
{
  y2debug ("Creating function call for %s", name.c_str ());
  TableEntry *func_te = table ()->find (name.c_str (), SymbolEntry::c_function);

  if (func_te == NULL)
  {
    y2internal ("No such function %s", name.c_str ());
    return NULL;
  }

  constTypePtr t = required_type ? required_type : (constFunctionTypePtr)func_te->sentry()->type ();
  return new Y2RubyFunction (m_name, name, t);
}

VALUE YRubyNamespace::getRubyModule()
{
  ruby_module_name = string("YCP::") + m_name;
  VALUE module = y2ruby_nested_const_get(ruby_module_name);
  if (module == Qnil)
  {
    y2warning ("The Ruby module '%s' is not provided by its rb file. Trying it without YCP prefix.", ruby_module_name.c_str());
    //old modules lives outside of YCP namespace
    ruby_module_name = m_name;
    module = y2ruby_nested_const_get(ruby_module_name);
  }
  return module;
}

int YRubyNamespace::addMethodsNewWay(VALUE module)
{
  VALUE methods = rb_funcall(module, rb_intern("published_methods"),0);
  methods = rb_funcall(methods,rb_intern("values"),0);
  int i;
  for (i = 0; i < RARRAY_LEN(methods); ++i)
  {
    VALUE method = rb_ary_entry(methods,i);
    VALUE method_name = rb_funcall(method, rb_intern("method_name"), 0);
    VALUE type = rb_funcall(method,rb_intern("type"),0);
    string signature = StringValueCStr(type);

    addMethod(RSTRING_PTR(method_name), signature, i);
  }
  return i;
}

int YRubyNamespace::addVariables(VALUE module, int offset)
{
  VALUE variables = rb_funcall(module, rb_intern("published_variables"),0);
  variables = rb_funcall(variables,rb_intern("values"),0);
  int j;
  for (j = 0; j < RARRAY_LEN(variables); ++j)
  {
    VALUE variable = rb_ary_entry(variables,j);
    VALUE variable_name = rb_funcall(variable, rb_intern("variable"), 0);
    VALUE type = rb_funcall(variable,rb_intern("type"),0);
    string signature = StringValueCStr(type);
    constTypePtr sym_tp = Type::fromSignature(signature);

    // symbol entry for the function
    SymbolEntry *se = new VariableSymbolEntry ( ruby_module_name,
      this,
      offset+j,// position. arbitrary numbering. must stay consistent when?
      rb_id2name(SYM2ID(variable_name)),
      sym_tp
    );
    se->setGlobal (true);
    // enter it to the symbol table
    enterSymbol (se, 0);
    y2milestone("variable: '%s' added", rb_id2name(SYM2ID(variable_name)));
  }
  return offset+j;
}

int YRubyNamespace::addMethodsOldWay(VALUE module)
{
  // we will perform operator- to determine the module methods
  VALUE moduleklassmethods = rb_funcall( rb_cModule, rb_intern("methods"), 0);
  VALUE mymodulemethods = rb_funcall( module, rb_intern("methods"), 0);
  VALUE methods = rb_funcall( mymodulemethods, rb_intern("-"), 1, moduleklassmethods );

  if (methods == Qnil)
  {
    y2internal ("Can't see methods in module '%s'", ruby_module_name.c_str());
    return 0;
  }

  int i;
  for(i = 0; i < RARRAY_LEN(methods); i++)
  {
    VALUE current = rb_funcall( methods, rb_intern("at"), 1, rb_fix_new(i) );
    if (rb_type(current) == RUBY_T_SYMBOL) {
  current = rb_funcall( current, rb_intern("to_s"), 0);
    }
    y2milestone("New method: '%s'", RSTRING_PTR(current));

    // figure out arity.
    Check_Type(module,T_MODULE);
    VALUE methodobj = rb_funcall( module, rb_intern("method"), 1, current );
    if ( methodobj == Qnil )
    {
      y2error ("Cannot access method object '%s'", RSTRING_PTR(current));
      continue;
    }
    string signature = "any( ";
    VALUE rbarity = rb_funcall( methodobj, rb_intern("arity"), 0);
    int arity = NUM2INT(rbarity);
    for ( int k=0; k < arity; ++k )
    {
      signature += "any";
      if ( k < (arity - 1) )
          signature += ",";
    }
    signature += ")";

    addMethod(RSTRING_PTR(current), signature, i);
  }
  return i;
}

int YRubyNamespace::addExceptionMethod(VALUE module, int offset)
{
  addMethod("last_exception", "string()", offset);
  return offset+1;
}

void YRubyNamespace::addMethod( const char* name, const string &signature, int offset)
{
  constTypePtr sym_tp = Type::fromSignature(signature);

  // symbol entry for the function
  SymbolEntry *fun_se = new SymbolEntry ( this,
    offset,// position. arbitrary numbering. must stay consistent when?
    name,
    SymbolEntry::c_function,
    sym_tp
  );

  fun_se->setGlobal (true);
  // enter it to the symbol table
  enterSymbol (fun_se, 0);
  y2debug("method: '%s' added", name);
}
