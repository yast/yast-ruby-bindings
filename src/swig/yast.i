%module ryast
%include std_string.i
%include stl.i
 %{
/* Includes the header in the wrapper code */
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

#include <y2/Y2ComponentBroker.h>
#include <y2/Y2Namespace.h>
#include <y2/Y2Component.h>
#include <y2/Y2Function.h>
#include <y2/SymbolEntry.h>
#include <y2util/Ustring.h>
#include <Y2.h>

#include <ycp/Import.h>

#include <ycp/pathsearch.h>

#define y2log_component "Y2Ruby"

//static swig_type_info _swigt__p_YCPValue;

 %}

#ifdef SWIGRUBY
//%include "ruby.i"
#endif

%rename("+") "operator+";
%rename("<<") "operator<<";
%rename("!=") "operator!=";
%rename("!") "operator!";
%rename("==") "operator==";
    
%typemap(in) int YCPValue {
  // TODO conver integers, and add support for lists, ah, and boleans!
  switch (TYPE($1))
  {
    case T_STRING:
    $result = YCPString(RSTRING ($1)->ptr);
    break;
    case T_TRUE:
    $result = YCPBoolean(true);
    break;
    case T_FALSE:
    $result = YCPBoolean(false);
    break;
    case T_FIXNUM:
    $result = YCPInteger(NUM2LONG($1));
    break;
    case T_FLOAT:
    $result = YCPFloat(NUM2DBL($1));
    break;
    case T_ARRAY:
    // FIXME
    break;
    case T_HASH:
    // FIXME
    break;
    case T_DATA:
    rb_raise( rb_eRuntimeError, "Object");
    break;
  }
  std::cout << TYPE($1) << std::endl;
  rb_raise( rb_eRuntimeError, "Conversion of Ruby type not supported");
  $result = YCPValue();
}

%typemap(out) YCPValue {
  // TODO
  // YT_BYTEBLOCK YT_PATH YT_SYMBOL YT_LIST YT_TERM YT_MAP YT_CODE YT_RETURN YT_BREAK YT_ENTRY YT_ERROR  YT_REFERENCE YT_EXTERNA
  if($1->isVoid())
  {
    $result = Qnil;
  }
  else if($1->isBoolean())
  {
    $result = $1->asBoolean()->value() ? Qtrue : Qfalse;
  }
  else if($1->isString())
  {
    $result = rb_str_new2($1->asString()->value().c_str());
  }
  else if($1->isInteger())
  {
    $result = INT2NUM( $1->asInteger()->value() );
  }
  else if( $1->isMap() )
  {
    VALUE rbhash;
    rbhash = rb_hash_new();
    YCPMap map = $1->asMap();
    printf("map size %d\n", map.size());
    
    for ( YCPMapIterator it = map.begin(); it != map.end(); ++it )
    {
      YCPValue *key = new YCPValue(it.key());
      YCPValue *value = new YCPValue(it.value());
      VALUE rkey = SWIG_NewPointerObj(key, SWIGTYPE_p_YCPValue, 1);
      VALUE rvalue = SWIG_NewPointerObj(value, SWIGTYPE_p_YCPValue, 1);
      rb_hash_aset(rbhash, rkey, rvalue );
    }
    $result = rbhash;
  }
  else if($1->isList())
  {
    VALUE rblist;
    rblist = rb_ary_new();
    YCPList list = $1->asList();
    printf("list size %d\n",list.size()); 
    for (int i=0; i < list.size(); i++)
    {
      YCPValue *value = new YCPValue(list.value(i));
       VALUE rvalue = SWIG_NewPointerObj(value, SWIGTYPE_p_YCPValue, 1);
      rb_ary_push( rblist, rvalue);
    }
    $result = rblist;
  }
  rb_raise( rb_eRuntimeError, "Conversion of YCP type %s not supported", $1->toString().c_str() );
  $result = Qnil;
}

//%include "y2util/RepDef.h"
%include "y2/Y2ComponentBroker.h"
%include "y2/Y2Namespace.h"
%include "y2/Y2Component.h"
%include "y2/Y2Function.h"

%ignore SymbolEntryPtr::_nameHash;
%ignore SymbolEntry::emptyUstring;
    
class SymbolEntry
{
public:
    //static UstringHash* _nameHash;
    //static Ustring emptyUstring;
public:
    typedef enum {
	c_unspec = 0,		//  0 unspecified local symbol (sets m_global = false)
	c_global,		//  1 unspecified global symbol (translates to c_unspec, sets m_global = true)
	c_module,		//  2 a module identifier
	c_variable,		//  3 a variable
	c_reference,		//  4 a reference to a variable
	c_function,		//  5 a defined function
	c_builtin,		//  6 a builtin function
	c_typedef,		//  7 a type
	c_const,		//  8 a constant (a read-only c_variable)
	c_namespace,		//  9 a namespace identifier
	c_self,			// 10 the current namespace (namespace prefix used in namespace definition)
	c_predefined,		// 11 a predefined namespace identifier
	c_filename		// 12 a filename (used in conjunction with TableEntry to store definition locations)
    } category_t;
public:
    // create symbol beloging to namespace (at position)
    SymbolEntry (const Y2Namespace* name_space, unsigned int position, const char *name, category_t cat, constTypePtr type);

    virtual ~SymbolEntry ();

    // symbols link to the defining namespace
    const Y2Namespace *nameSpace () const;
    void setNamespace (const Y2Namespace *name_space);
    virtual bool onlyDeclared () const { return false; }

    unsigned int position () const;
    void setPosition (unsigned int position);

    bool isGlobal () const;
    void setGlobal (bool global);

    bool isModule () const { return m_category == c_module; }
    bool isVariable () const { return m_category == c_variable; }
    bool isReference () const { return m_category == c_reference; }
    bool isFunction () const { return m_category == c_function; }
    bool isBuiltin () const { return m_category == c_builtin; }
    bool isNamespace () const { return m_category == c_namespace; }
    bool isSelf () const { return m_category == c_self; }
    bool isFilename () const { return m_category == c_filename; }
    bool isPredefined () const { return m_category == c_predefined; }

    bool likeNamespace () const { return isModule() || isNamespace() || isSelf(); }

    const char *name () const;
    category_t category () const;
    void setCategory (category_t cat);
    constTypePtr type () const;
    string catString () const;
    void setType (constTypePtr type);
    YCPValue setValue (YCPValue value);
    YCPValue value () const;
    
    void push ();
    void pop ();

    virtual string toString (bool with_type = true) const;
};

template < typename T >
class Ptr {
  public:
  T *operator->();
};
%template (SymbolEntryPtr) Ptr<SymbolEntry>;

%include "ycp/SymbolTable.h"

%include "ycp/Import.h"
%include "ycp/Type.h"
%include "ycp/TypePtr.h"
