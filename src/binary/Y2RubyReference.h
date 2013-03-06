#ifndef Y2RubyRefence_h
#define Y2RubyRefence_h

#include <ruby.h>
#include <ycp/YCPValue.h>
#include <ycp/YCPList.h>
#include <ycp/YCPVoid.h>
#include <y2/Y2Function.h>
#include <y2/Y2Namespace.h>

class ClientFunction : public Y2Function
{
private:
  VALUE object;
  YCPList m_call;
public:
  ClientFunction(VALUE m_object) : object(m_object)
  {}

  YCPValue evaluateCall ();

  /**
  * Attaches a parameter to a given position to the call.
  * @return false if there was a type mismatch
  */
  bool attachParameter (const YCPValue& arg, const int position)
  {
    m_call->set (position, arg);
    return true;
  }

  constTypePtr wantedParameterType() const
  {
    return Type::Any;
  }

  std::string name() const
  {
    return "ruby_reference";
  }

  /**
   * Appends a parameter to the call.
   * @return false if there was a type mismatch
   */
  bool appendParameter (const YCPValue& arg)
  {
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
};

class ClientNamespace : public Y2Namespace
{
private:
   ClientFunction f; 
public:
  ClientNamespace(VALUE m_object) : f(m_object)
  {}

  Y2Function* createFunctionCall(const string name, constFunctionTypePtr type)
  {
    return &f;
  }

  virtual const string filename() const
  {
    return "RubyReference";
  }

  virtual YCPValue evaluate(bool cse)
  {
    return YCPVoid();
  }


};

#endif
