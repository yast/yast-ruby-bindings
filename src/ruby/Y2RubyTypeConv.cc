
#include <ycp/y2log.h>

#include <ycp/YCPValue.h>
#include <ycp/YCPBoolean.h>
#include <ycp/YCPList.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPString.h>
#include <ycp/YCPInteger.h>
#include <ycp/YCPFloat.h>
#include <ycp/YCPElement.h>
#include <ycp/YCPSymbol.h>
#include <ycp/YCPPath.h>
#include <ycp/YCPVoid.h>
#include <ycp/Import.h>

#include "Y2RubyTypeConv.h"

/**
 * Converts a YCPValue into a Ruby Value
 * Supports neested lists using recursion.
 */
extern "C" VALUE
ycpvalue_2_rbvalue( YCPValue ycpval )
{
  // TODO
  // YT_BYTEBLOCK YT_PATH YT_SYMBOL YT_LIST YT_TERM YT_MAP YT_CODE YT_RETURN YT_BREAK YT_ENTRY YT_ERROR  YT_REFERENCE YT_EXTERNA
  if (ycpval->isVoid())
  {
    return Qnil;
  }
  else if (ycpval->isBoolean())
  {
    return ycpval->asBoolean()->value() ? Qtrue : Qfalse;
  }
  else if (ycpval->isString())
  {
    return rb_str_new2(ycpval->asString()->value().c_str());
  }
  else if (ycpval->isInteger())
  {
    return INT2NUM( ycpval->asInteger()->value() );
  }
  else if ( ycpval->isMap() )
  {
    VALUE rbhash;
    rbhash = rb_hash_new();
    YCPMap map = ycpval->asMap();
    y2internal("map size %d\n", (int) map.size());

    for ( YCPMapIterator it = map.begin(); it != map.end(); ++it )
    {
      YCPValue key = it.key();
      YCPValue value = it.value();
      rb_hash_aset(rbhash, ycpvalue_2_rbvalue(key), ycpvalue_2_rbvalue(value) );
    }
    return rbhash;
  }
  else if (ycpval->isList())
  {
    VALUE rblist;
    rblist = rb_ary_new();
    YCPList list = ycpval->asList();
    y2internal("list size %d\n",list.size());
    for (int i=0; i < list.size(); i++)
    {
      rb_ary_push( rblist, ycpvalue_2_rbvalue(list.value(i)));
    }
    return rblist;
  }
  else if (ycpval->isSymbol())
  {
    YCPSymbol symbol = ycpval->asSymbol();
    return rb_intern(symbol->symbol_cstr());
  }
  rb_raise( rb_eRuntimeError, "Conversion of YCP type %s not supported", ycpval->toString().c_str() );
  return Qnil;
}

// isEmpty size add remove (value n) toString
YCPValue
rbvalue_2_ycpvalue( VALUE value )
{
  y2internal("type: '%d'", TYPE(value));
  // TODO conver integers, and add support for lists, ah, and boleans!
  switch (TYPE(value))
  {
  case T_NIL:
    return YCPVoid();
  case T_STRING:
    return YCPString(RSTRING (value)->ptr);
    break;
  case T_TRUE:
    return YCPBoolean(true);
    break;
  case T_FALSE:
    return YCPBoolean(false);
    break;
  case T_FIXNUM:
    return YCPInteger(NUM2LONG(value));
    break;
  case T_FLOAT:
    return YCPFloat(NUM2DBL(value));
    break;
  case T_ARRAY:
    // FIXME
    return YCPValue();
    break;
  case T_HASH:
    // FIXME
    return YCPValue();
    break;
  case T_SYMBOL:
    y2internal("mira un mono!!!");
    //return YCPSymbol(RSTRING(rb_funcall(value, rb_intern("to_s"), 0))->ptr);
    return YCPSymbol(rb_id2name(rb_to_id(value)));
    
  case T_DATA:
    rb_raise( rb_eRuntimeError, "Object");
    break;
  default:
    std::cout << TYPE(value) << std::endl;
    rb_raise( rb_eRuntimeError, "Conversion of Ruby type not supported");
    return YCPValue();
  }
}

YCPValue
rbvalue_2_ycppath( VALUE value )
{
  VALUE stringrep = rb_funcall(value, rb_intern("to_s"), 0);
  return  YCPPath(RSTRING(stringrep)->ptr);
}