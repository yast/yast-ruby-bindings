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

/*
 * Y2RubyTypeConv.cc provides type mapping between YaST (YCPValue)
 * and Ruby (VALUE) with
 * 
 * extern "C" VALUE ycpvalue_2_rbvalue( YCPValue ycpval )
 * 
 * YCPValue rbvalue_2_ycpvalue( VALUE value )
 *
 */

#include <ycp/y2log.h>

#include <ycp/YCPValue.h>
#include <ycp/YCPBoolean.h>
#include <ycp/YCPList.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPString.h>
#include <ycp/YCPInteger.h>
#include <ycp/YCPTerm.h>
#include <ycp/YCPFloat.h>
#include <ycp/YCPElement.h>
#include <ycp/YCPSymbol.h>
#include <ycp/YCPPath.h>
#include <ycp/YCPVoid.h>
#include <ycp/YCPExternal.h>
#include <ycp/Import.h>

#include "Y2RubyTypePath.h"
#include "Y2RubyTypeTerm.h"

#include "Y2RubyTypeConv.h"

#define IS_A(obj,klass) ((rb_obj_is_kind_of((obj),(klass))==Qtrue)?1:0)

/*
 * rbhash_2_ycpmap
 * 
 * Internal helper for Hash -> YCPMap
 * 
 */

static YCPMap rbhash_2_ycpmap( VALUE value )
{
  YCPMap map;
  VALUE keys = rb_funcall(value, rb_intern("keys"), 0);
  int n = NUM2LONG(rb_funcall(keys, rb_intern("size"), 0));
  for ( int i=0; i<n; ++i)
  {
    VALUE rkey = rb_funcall(keys, rb_intern("at"), 1, INT2NUM(i));
    YCPValue ykey = rbvalue_2_ycpvalue(rkey);
    YCPValue yvalue = rbvalue_2_ycpvalue( rb_funcall(value, rb_intern("[]"), 1, rkey) );
    map.add(ykey, yvalue);
  }
  return map;
}


/*
 * rbarray_2_ycplist
 * 
 * Internal helper for Array -> YCPList
 * 
 */

static YCPList rbarray_2_ycplist( VALUE value )
{
  YCPList list;
  int n = NUM2LONG(rb_funcall(value, rb_intern("size"), 0));
  for ( int i=0; i<n; ++i)
  {
    VALUE element = rb_funcall(value, rb_intern("[]"), 1, INT2NUM(i));
    list.add( rbvalue_2_ycpvalue(element) );
  }
  return list;
}


#define YCP_EXTERNAL_MAGIC "Ruby object"

static YCPExternal rbobject_2_ycpexternal( VALUE value )
{
  YCPExternal ex((void*) value, string(YCP_EXTERNAL_MAGIC), NULL);
  return ex;
}

/**
 * 
 * ycpvalue_2_rbvalue
 * 
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
  else if (ycpval->isPath())
  {
    // FIXME implement a ruby class for YCPPath
    return rb_str_new2(ycpval->asPath()->asString()->value().c_str());
  }
  else if (ycpval->isTerm())
  {
    return ryast_rterm_from_yterm(ycpval->asTerm());
  }
  else if (ycpval->isInteger())
  {
    return INT2NUM( ycpval->asInteger()->value() );
  }
  else if (ycpval->isFloat())
  {
    return rb_float_new(ycpval->asFloat()->value());
  }
  else if ( ycpval->isMap() )
  {
    VALUE rbhash;
    rbhash = rb_hash_new();
    YCPMap map = ycpval->asMap();
    //y2internal("map size %d\n", (int) map.size());

    for (YCPMap::const_iterator it = map->begin(); it != map->end(); ++it)
    {
      YCPValue key = it->first;
      YCPValue value = it->second;
      rb_hash_aset(rbhash, ycpvalue_2_rbvalue(key), ycpvalue_2_rbvalue(value) );
    }
    return rbhash;
  }
  else if (ycpval->isList())
  {
    VALUE rblist;
    rblist = rb_ary_new();
    YCPList list = ycpval->asList();
    //y2internal("list size %d\n",list.size());
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
  else if (ycpval->isExternal())
  {
    YCPExternal ex = ycpval->asExternal();
    if (ex->magic() == string(YCP_EXTERNAL_MAGIC)) {
      return (VALUE)(ex->payload()); // FIXME reference counting
    }
    y2error("Unexpected magic '%s'.", (ex->magic()).c_str());
  }
  rb_raise( rb_eTypeError, "Conversion of YCP type %s not supported", ycpval->toString().c_str() );
  return Qnil;
}


// isEmpty size add remove (value n) toString

/*
 * rbvalue_2_ycpvalue
 * 
 * Converts Ruby VALUE to YCP YCPValue
 * 
 */

YCPValue
rbvalue_2_ycpvalue( VALUE value )
{
  //VALUE klass = rb_funcall( value, rb_intern("class"), 0);
  //std::cout << StringValuePtr( rb_funcall( klass, rb_intern("to_s"), 0)) << " | " << StringValuePtr(rb_funcall( value, rb_intern("inspect"), 0)) << std::endl;
  //y2internal("type: '%d'", TYPE(value));
  // TODO convert integers, and add support for lists
  switch (TYPE(value))
  {
  case T_NIL:
    return YCPVoid();
  case T_STRING:
    return YCPString(StringValuePtr(value));
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
    return rbarray_2_ycplist(value);
    break;
  case T_HASH:
    return rbhash_2_ycpmap(value);
    break;
  case T_SYMBOL:
    return YCPSymbol(rb_id2name(rb_to_id(value)));
  //case T_DATA:
  //  rb_raise( rb_eRuntimeError, "Object");
    break;
  default:
      {
	VALUE cname = rb_funcall(rb_funcall(value, rb_intern("class"), 0), rb_intern("to_s"), 0);
	const char *class_name = StringValuePtr(cname);
	/* get the Term class object */
	if ( !strcmp(class_name, "YaST::Term") )
	  {
	    return ryast_yterm_from_rterm(value);
	  }

        return rbobject_2_ycpexternal(value);
      }
  }
}


/*
 * rbvalue_2_ycppath
 * 
 * Converts Ruby value to YCPPath
 * 
 */

YCPValue
rbvalue_2_ycppath( VALUE value )
{
  VALUE stringrep = rb_funcall(value, rb_intern("to_s"), 0);
  return  YCPPath(StringValuePtr(stringrep));
}
