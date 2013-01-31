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

#include <cassert>

#include "YRuby.h"

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
  VALUE list = rb_funcall(value, rb_intern("to_a"), 0); //get array of two items array, first is key and second is value
  for ( unsigned i=0; i<RARRAY_LEN(list); ++i)
  {
    VALUE kv_list = *(RARRAY_PTR(list)+i);
    YCPValue ykey = rbvalue_2_ycpvalue(*RARRAY_PTR(kv_list));
    YCPValue yvalue = rbvalue_2_ycpvalue(*(RARRAY_PTR(kv_list)+1));
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
  int n = RARRAY_LEN(value);
  for ( int i=0; i<n; ++i)
  {
    list.add(rbvalue_2_ycpvalue(*(RARRAY_PTR(value)+i)));
  }
  return list;
}


#define YCP_EXTERNAL_MAGIC "Ruby object"

static void ycpexternal_finalizer(void * value_v, string /*magic*/)
{
  VALUE value = (VALUE)value_v;

  if (!YRuby::yRuby()) {
    return; // we're finalized
  }

  YRuby::refcount_map_t& vrby = YRuby::yRuby()->value_references_from_ycp;
  YRuby::refcount_map_t::iterator it = vrby.find(value);
  if (it == vrby.end()) {
    // YRuby got re-constructed during final cleanup; do nothing
    return;
  }

  int & count = it->second;
  --count;
  y2internal("Refcount of value %ld decremented to %d", value, count);
  assert(count >= 0);

  if (count == 0) {
    vrby.erase(it);
  }
}

static YCPExternal rbobject_2_ycpexternal( VALUE value )
{
  YCPExternal ex((void*) value, string(YCP_EXTERNAL_MAGIC), ycpexternal_finalizer);

  // defaults to zero, ok
  int count = ++YRuby::yRuby()->value_references_from_ycp[value];
  y2internal("Refcount of value %ld incremented to %d", value, count);
  return ex;
}

static YCPValue
rbpath_2_ycppath( VALUE value )
{
  VALUE stringrep = rb_funcall(value, rb_intern("to_s"), 0);
  return  YCPPath(StringValuePtr(stringrep));
}
static YCPValue
rbterm_2_ycpterm( VALUE value )
{
  VALUE id = rb_funcall(value, rb_intern("value"), 0);
  VALUE params = rb_funcall(value, rb_intern("params"), 0);
  const char * id_s = rb_id2name(SYM2ID(id));
  if (params == Qnil)
    return YCPTerm(id_s);
  return YCPTerm(id_s,rbarray_2_ycplist(params));
}


/*
 * rbvalue_2_ycpvalue
 *
 * Converts Ruby VALUE to YCP YCPValue
 *
 */

YCPValue
rbvalue_2_ycpvalue( VALUE value )
{
  // TODO convert integers
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
  case T_BIGNUM:
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
    const char *class_name = rb_obj_classname(value);
    if ( !strcmp(class_name, "YCP::Path"))
    {
      return rbpath_2_ycppath(value);
    }
    else if ( !strcmp(class_name, "YCP::Term"))
    {
      return rbterm_2_ycpterm(value);
    }
    else
    {
      return rbobject_2_ycpexternal(value);
    }
  }
  }
}




