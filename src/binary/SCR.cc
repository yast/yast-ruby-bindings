#include <string>

#include "ycp/y2log.h"
#include "ycp/ExecutionEnvironment.h"

#include "scr/SCR.h"
#include "scr/ScriptingAgent.h"

#include "ruby.h"

#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"

static VALUE rb_mSCR;
static VALUE rb_mYCP;
static SCR scr;
static ScriptingAgent scra;

class RubyLogger : public Logger
{
  static RubyLogger* m_rubylogger;
public:
  void error(string message)
  {
    y2_logger (LOG_ERROR,"Ruby",YaST::ee.filename().c_str(), YaST::ee.linenumber(),"",message.c_str());
  }

  void warning(string message)
  {
    y2_logger (LOG_WARNING,"Ruby",YaST::ee.filename().c_str(), YaST::ee.linenumber(),"",message.c_str());
  }

  static RubyLogger* instance()
  {
    if (!m_rubylogger)
      m_rubylogger = new RubyLogger();
    return m_rubylogger;
  }
};

RubyLogger* RubyLogger::m_rubylogger = NULL;

extern "C" {
  static VALUE
  scr_call_builtin( int argc, VALUE *argv, VALUE self )
  {
    if (argc<2)
      rb_raise(rb_eArgError, "At least two arguments must be passed");
    extern StaticDeclaration static_declarations;
    std::string qualified_name = std::string("SCR::") + RSTRING_PTR(argv[0]);

    declaration_t *bi_dt = static_declarations.findDeclaration(qualified_name.c_str());
    if (bi_dt==NULL)
      rb_raise(rb_eNameError, "No such builtin '%s'", qualified_name.c_str());

    YEBuiltin bi_call(bi_dt);
    for (int i = 1; i<argc; ++i)
    {
      YCPValue param_v = rbvalue_2_ycpvalue(argv[i]);
      YConstPtr param_c = new YConst(YCode::ycConstant, param_v);
      constTypePtr err_tp = bi_call.attachParameter ( param_c, Type::vt2type(param_v->valuetype()));

      if (err_tp != NULL)
      {
        if (err_tp->isError())
          rb_raise(rb_eArgError,"Too much parameters passed");
        else
          rb_raise(rb_eRuntimeError,"attachParameter failed: %s",err_tp->toString().c_str());
      }
    }

    constTypePtr err_tp = bi_call.finalize(RubyLogger::instance());
    if (err_tp != NULL)
      rb_raise(rb_eRuntimeError,"Error when finalizing builtin call: %s",err_tp->toString().c_str());

    return ycpvalue_2_rbvalue(bi_call.evaluate(false));
  }
}

extern "C"
{
  /*
   * Ruby module initializer
   *
   * "require 'ycpx'" will call Init_ycpx()
   */

  void
  Init_scrx()
  {
    /*
     * module YCP
     */
    rb_mYCP = rb_define_module("YCP");
    rb_mSCR = rb_define_module_under(rb_mYCP, "SCR");
    rb_define_singleton_method( rb_mSCR, "call_builtin", RUBY_METHOD_FUNC(scr_call_builtin), -1);
  }
}
