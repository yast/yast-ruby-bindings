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
#include <exception>

#include "YRuby.h"
#include "Y2RubyUtils.h"


// HELPER method to inspect ruby values from C++. Useful for debugging
/*
// usage: log_inspect("surely not nil, foobar", foobar);
static void log_inspect(const char * message, VALUE v)
{
  VALUE inspect = rb_funcall(v, rb_intern("inspect"), 0);
  y2internal("%s: %s", message, StringValueCStr(inspect));
}
*/

/**
 * Exception raised when type signature in ruby class is invalid
 */
class WrongTypeException: public std::exception
{
public:

  WrongTypeException(string method_name, string signature)
  {
    message += "Invalid type '";
    message += signature;
    message += "' definition for method/variable: '";
    message += method_name;
    message += "'.";
  }

  virtual const char* what() const throw()
  {
    return message.c_str();
  }

  virtual ~WrongTypeException() throw() {}
private:
  string message;
};

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
    y2debug("Called set value on %s::%s with %s",module_name.c_str(), name(), value->toString().c_str());
    return YRuby::yRuby()->callInner ( module_name,
      method_name,
      l,
      type()
    );
  }

  YCPValue value () const
  {
    YCPValue result = YRuby::yRuby()->callInner ( module_name,
      name(),
      YCPList(),
      type()
    );
    y2debug("Called value on %s::%s and return %s",module_name.c_str(), name(), result->toString().c_str());
    return result;
  }

};

void YRubyNamespace::constructSymbolTable(VALUE module)
{
  int offset = 0; //track number of added method, so we can add extra one at the end
  VALUE module_class = rb_obj_class(module);
  if (rb_respond_to(module_class, rb_intern("published_functions" )))
  {
    offset = addMethods(module_class);
    offset = addVariables(module_class, offset);
  }
  else
  {
    y2error("Module '%s' doesn't export anything. DEPRECATED old way", m_name.c_str());
    return;
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
  return ".../" + m_name;
}

// this is for error reporting only?
string YRubyNamespace::toString () const
{
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
  ruby_module_name = string("Yast::") + m_name;
  VALUE module = y2ruby_nested_const_get(ruby_module_name);
  return module;
}

int YRubyNamespace::addMethods(VALUE module)
{
  VALUE methods = rb_funcall(module, rb_intern("published_functions"),0);
  int j = 0;
  for (int i = 0; i < RARRAY_LEN(methods); ++i)
  {
    VALUE method = rb_ary_entry(methods, i);
    VALUE method_name = rb_ary_entry(method, 0);
    VALUE type = rb_ary_entry(method, 1);
    string signature = StringValueCStr(type);

    addMethod(rb_id2name(SYM2ID(method_name)), signature, j++);
  }
  return j;
}

int YRubyNamespace::addVariables(VALUE module, int offset)
{
  VALUE variables = rb_funcall(module, rb_intern("published_variables"),0);
  int j=0;
  for (int i = 0; i < RARRAY_LEN(variables); ++i)
  {
    VALUE variable = rb_ary_entry(variables, i);
    VALUE variable_name = rb_ary_entry(variable, 0);
    VALUE type = rb_ary_entry(variable, 1);
    string signature = StringValueCStr(type);
    constTypePtr sym_tp = Type::fromSignature(signature);

    if (sym_tp == NULL)
      throw WrongTypeException(rb_id2name(SYM2ID(variable_name)), signature);

    // symbol entry for the function
    SymbolEntry *se = new VariableSymbolEntry ( ruby_module_name,
      this,
      offset+(j++),// position. arbitrary numbering. must stay consistent when?
      rb_id2name(SYM2ID(variable_name)),
      sym_tp
    );
    se->setGlobal (true);
    // enter it to the symbol table
    enterSymbol (se, 0);
    y2debug("variable: '%s' added", rb_id2name(SYM2ID(variable_name)));
  }
  return offset+j;
}

int YRubyNamespace::addExceptionMethod(VALUE module, int offset)
{
  addMethod("last_exception", "string()", offset);
  return offset+1;
}

void YRubyNamespace::addMethod( const char* name, const string &signature, int offset)
{
  constTypePtr sym_tp = Type::fromSignature(signature);
  if (sym_tp == NULL || !sym_tp->isFunction())
    throw WrongTypeException(name, signature);

  // symbol entry for the function
  SymbolEntryPtr fun_se = new SymbolEntry ( this,
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
