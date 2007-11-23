%module ycpx
%include std_string.i
%include stl.i
%include file.i
 %{
/* Includes the header in the wrapper code */
#define y2log_component "Y2Ruby"
#include <y2util/y2log.h>

#include <ycp/YCode.h>
#include <ycp/YCPCode.h>
#include <ycp/YCPElement.h>
#include <ycp/YCPExternal.h>
#include <ycp/YCPValue.h>
#include <ycp/YCPBoolean.h>
#include <ycp/YCPList.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPString.h>
#include <ycp/YCPInteger.h>
#include <ycp/YCPFloat.h>
#include <ycp/YCPPath.h>
#include <ycp/YCPTerm.h>
#include <ycp/YCPVoid.h>
#include <ycp/Import.h>
#include <ycp/YBlock.h>
#include <ycp/YCPByteblock.h>
#include <ycp/Parser.h>
#include <ycp/pathsearch.h>
#include <y2util/Rep.h>

//static swig_type_info _swigt__p_YCPValue;

%}

%rename("+") "operator+";
%rename("<<") "operator<<";
%rename("!=") "operator!=";
%rename("!") "operator!";
%rename("==") "operator==";

//%include <y2util/Rep.h>

%include <ycp/YCPCode.h>

//%include <ycp/YCPElement.h>
//%include <ycp/YCPExternal.h>
%include <ycp/YCPValue.h>

%nodefaultctor YCPBoolean;
%include <ycp/YCPBoolean.h>

//%include <ycp/YCPList.h>
//%include <ycp/YCPMap.h>

%nodefaultctor YCPString;
%include <ycp/YCPString.h>

%nodefaultctor YCPInteger;
%include <ycp/YCPInteger.h>

%nodefaultctor YCPFloat;
%include <ycp/YCPFloat.h>

//%include <ycp/Import.h>

%nodefaultctor YCPExternal;
%include <ycp/YCPExternal.h>

%nodefaultctor YCPSymbol;
%include <ycp/YCPSymbol.h>

%nodefaultctor YCPTerm;
%include <ycp/YCPTerm.h>

%nodefaultctor YCPByteblock;
%include <ycp/YCPByteblock.h>

%include <ycp/YCode.h>
%predicate YCode::isBlock();
%predicate YCode::isStatement();

class YCodePtr
{
  public:
  YCodePtr(const YCodePtr &);
  YCodePtr(YCode*);
  YCode* operator->();
};

%include <ycp/Parser.h>
//%include <ycp/pathsearch.h>

%include <ycp/YBlock.h>