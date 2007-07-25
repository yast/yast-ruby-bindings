#include "YRubyNamespace.h"

// Ruby stuff
#include <ruby.h>

#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>

#include <ycp/YCPElement.h>
#include <ycp/Type.h>
#include <ycp/YCPVoid.h>
//#include <YCP.h>
#include "YRuby.h"
#include <stdio.h>

/**
 * using this instead of plain strcmp
 * enables embedding argument names into the typeinfo
 */
static bool firstWordIs (const char *where, const char *what)
{
  size_t n = strlen (what);
  return !strncmp (where, what, n) &&
         (where[n] == '\0' || isspace (where[n]));
}

/**
 * The definition of a function that is implemented in Ruby
 */
class Y2RubyFunctionCall : public Y2Function
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
  Y2RubyFunctionCall (const string &module_name,
                      const string &local_name,
                      constFunctionTypePtr function_type
                     ) :
      m_module_name (module_name),
      m_local_name (local_name),
      m_type (function_type)
  {
    // placeholder, formerly function name
    m_call->add (YCPVoid ());
  }

  //! if true, the perl function is passed the module name
  virtual bool isMethod () = 0;

  //! called by YEFunction::evaluate
  virtual YCPValue evaluateCall ()
  {
    return YRuby::yRuby()->callInner ( m_module_name,
                                       m_local_name,
                                       isMethod (),
                                       m_call,
                                       m_type->returnType() );
  }
  /**
  * Attaches a parameter to a given position to the call.
  * @return false if there was a type mismatch
  */
  virtual bool attachParameter (const YCPValue& arg, const int position)
  {
    m_call->set (position+1, arg);
    return true;
  }

  /**
   * What type is expected for the next appendParameter (val) ?
   * (Used when calling from Ruby, to be able to convert from the
   * simple type system of Ruby to the elaborate type system of YCP)
   * @return Type::Any if number of parameters exceeded
   */
  virtual constTypePtr wantedParameterType () const
  {
    // -1 for the function name
    int params_so_far = m_call->size ()-1;
    return m_type->parameterType (params_so_far);
  }

  /**
   * Appends a parameter to the call.
   * @return false if there was a type mismatch
   */
  virtual bool appendParameter (const YCPValue& arg)
  {
    y2internal("Adding parameter to function %s::%s of type %s", m_module_name.c_str(), m_local_name.c_str(), arg->valuetype_str());
    m_call->add (arg);
    return true;
  }

  /**
   * Signal that we're done adding parameters.
   * @return false if there was a parameter missing
   */
  virtual bool finishParameters ()
  {
    return true;
  }


  virtual bool reset ()
  {
    m_call = YCPList ();
    // placeholder, formerly function name
    m_call->add (YCPVoid ());
    return true;
  }

  /**
   * Something for remote namespaces
   */
  virtual string name () const
  {
    return m_local_name;
  }
};

class Y2RubySubCall : public Y2RubyFunctionCall
{
public:
  Y2RubySubCall (const string &module_name,
                 const string &local_name,
                 constFunctionTypePtr function_type
                ) :
      Y2RubyFunctionCall (module_name, local_name, function_type)
  {}
  virtual bool isMethod ()
  {
    return false;
  }
};

class Y2RubyMethodCall : public Y2RubyFunctionCall
{
public:
  Y2RubyMethodCall (const string &module_name,
                    const string &local_name,
                    constFunctionTypePtr function_type
                   ) :
      Y2RubyFunctionCall (module_name, local_name, function_type)
  {}
  virtual bool isMethod ()
  {
    return true;
  }
};



YRubyNamespace::YRubyNamespace (string name)
    : m_name (name),
    m_all_methods (true)
{
  y2milestone("Creating namespace for '%s'", name.c_str());

  //y2milestone("loadModule 3.5");
  //VALUE result = rb_eval_string((require_module).c_str());
  
  VALUE module = rb_funcall( rb_mKernel, rb_intern("const_get"), 1, rb_str_new2(name.c_str()) );
  if (module == Qnil)
  {
    y2error ("The Ruby module '%s' is not provided by its rb file", name.c_str());
    return;
  }
  y2milestone("The module '%s' was found", name.c_str());

  // we will perform operator- to determine the module methods
  VALUE moduleklassmethods = rb_funcall( rb_cModule, rb_intern("methods"), 0);
  VALUE mymodulemethods = rb_funcall( module, rb_intern("methods"), 0);
  VALUE methods = rb_funcall( mymodulemethods, rb_intern("-"), 1, moduleklassmethods );
      
  if (methods == Qnil)
  {
    y2error ("Can't see methods in module '%s'", name.c_str());
    return;
  }
  
  int i;
  for(i = 0; i < RARRAY(methods)->len; i++)
  {
    VALUE current = RARRAY(methods)->ptr[i];
    y2milestone("New method: '%s'", RSTRING(current)->ptr);
    
    constTypePtr sym_tp = Type::Unspec;
    //sym_tp = parseTypeinfo (*sym_ti)
    if (sym_tp->isError ())
    {
      y2error ("Cannot parse $TYPEINFO{%s}", RSTRING(current)->ptr);
      continue;
    }
    if (sym_tp->isUnspec ())
    {
      //sym_tp = new FunctionType (Type::Any, new FunctionType(Type::Any) );
      // figure out arity.
      y2milestone("1.");
      Check_Type(module,T_MODULE);
      VALUE methodobj = rb_funcall( module, rb_intern("method"), 1, current );
      //VALUE methodobj = rb_funcall( module, rb_intern("send"), 2, rb_str_new2("method"), current );
      if ( methodobj == Qnil )
      {
        y2error ("Cannot access method object '%s'", RSTRING(current)->ptr);
        continue;
      }
      y2milestone("2.");
      string signature = "any( ";
      VALUE rbarity = rb_funcall( methodobj, rb_intern("arity"), 0);
      y2milestone("3.");
      int arity = NUM2INT(rbarity);
      for ( int k=0; k < arity; ++k )
      {
        signature += "any";
        if ( k < (arity - 1) )
            signature += ",";
      }
      signature += ")";
      y2internal("going to parse signature: '%s'", signature.c_str());
      sym_tp = Type::fromSignature(signature);
    }
    
    constFunctionTypePtr fun_tp = (constFunctionTypePtr) sym_tp;

    // symbol entry for the function
    SymbolEntry *fun_se = new SymbolEntry ( this,
                                            i,// position. arbitrary numbering. must stay consistent when?
                                            RSTRING(current)->ptr, // passed to Ustring, no need to strdup
                                            SymbolEntry::c_function,
                                            sym_tp);
    fun_se->setGlobal (true);
    // enter it to the symbol table
    enterSymbol (fun_se, 0);
    y2milestone("method: '%s' added", RSTRING(current)->ptr);
    y2milestone("%s", symbolsToString().c_str());
  }
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

// It seems that this is the standard implementation. why would we
// ever want it to be different?
Y2Function* YRubyNamespace::createFunctionCall (const string name, constFunctionTypePtr required_type)
{
  y2debug ("Creating function call for %s", name.c_str ());
  TableEntry *func_te = table ()->find (name.c_str (), SymbolEntry::c_function);
  if (func_te)
  {
    constTypePtr t = required_type ? required_type : (constFunctionTypePtr)func_te->sentry()->type ();
    if (m_all_methods)
    {
      return new Y2RubyMethodCall (m_name, name, t);
    }
    else
    {
      return new Y2RubySubCall (m_name, name, t);
    }
  }
  y2error ("No such function %s", name.c_str ());
  return NULL;
}
