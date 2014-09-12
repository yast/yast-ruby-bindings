#include "Y2RubyReference.h"
#include "Y2RubyTypeConv.h"
#include "Y2YCPTypeConv.h"

YCPValue ClientFunction::evaluateCall()
{
//TODO exception handling
  VALUE *params = new VALUE[m_call.size()];
  for (int i = 0; i < m_call.size(); ++i)
  {
    VALUE value = ycpvalue_2_rbvalue(m_call.value(i));
    RB_GC_GUARD(value);
    params[i] = value;
  }
  YCPValue res = rbvalue_2_ycpvalue(rb_funcall3(object, rb_intern("call"),m_call.size(), params));
  delete[] params;
  return res;
}
