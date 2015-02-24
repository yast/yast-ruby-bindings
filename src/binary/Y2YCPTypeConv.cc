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
#include <ycp/YCPCode.h>
#include <ycp/YCPBoolean.h>
#include <ycp/YCPByteblock.h>
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

#include "Y2YCPTypeConv.h"
#include "Y2RubyUtils.h"

//must match same magic id as in vica versa conversion
#define YCP_EXTERNAL_MAGIC "Ruby object"

extern "C" VALUE
ycp_path_to_rb_path( YCPPath ycppath )
{
  if (!y2_require("yast/path"))
  {
    y2internal("Cannot find yast/path module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("Path"));
  VALUE value = yrb_utf8_str_new(ycppath->toString());
  return rb_class_new_instance(1,&value,cls);
}

extern "C" VALUE
ycp_term_to_rb_term( YCPTerm ycpterm )
{
  if (!y2_require("yast/term"))
  {
    y2internal("Cannot find yast/term module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("Term"));
  VALUE params = ycpvalue_2_rbvalue(ycpterm->args());
  if (params == Qnil)
    params = rb_ary_new2(1);
//we need to pass array of parameters to work properly with unlimited params in ruby
  rb_ary_unshift(params, ID2SYM(rb_intern(ycpterm->name().c_str())));
  return rb_class_new_instance(RARRAY_LEN(params), RARRAY_PTR(params),cls);
}

extern "C" VALUE
ycp_ref_to_rb_ref( YCPReference ycpref )
{
  if (!y2_require("yastx"))
  {
    y2internal("Cannot find yastx module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("YReference"));
  return Data_Wrap_Struct(cls, 0, NULL, (void*)&*ycpref->entry());
}

extern "C" void
rb_bb_free(void *p)
{
  YCPByteblock *bb = (YCPByteblock*) p;
  delete bb;
}

extern "C" VALUE
ycp_bb_to_rb_bb( YCPByteblock ycpbb )
{
  if (!y2_require("yastx"))
  {
    y2internal("Cannot find yastx module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("Byteblock"));
  return Data_Wrap_Struct(cls, 0, rb_bb_free, new YCPByteblock(ycpbb->value(), ycpbb->size()));
}

extern "C" void
rb_yc_free(void *p)
{
  YCPCode *yc = (YCPCode*) p;
  delete yc;
}

extern "C" VALUE
ycp_code_to_rb_code( YCPCode ycode )
{
  if (!y2_require("yastx"))
  {
    y2internal("Cannot find yastx module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("YCode"));
  YCPCode * yc = new YCPCode(ycode);
  VALUE res = Data_Wrap_Struct(cls, 0, rb_yc_free, yc);
  rb_obj_call_init(res,0, NULL);
  return res;
}

extern "C" void
rb_ext_free(void *p)
{
  YCPExternal *ext = (YCPExternal*) p;
  delete ext;
}

extern "C" VALUE
ycp_ext_to_rb_ext( YCPExternal ext )
{
  y2debug("Convert ext %s", ext->toString().c_str());
  if (!y2_require("yast"))
  {
    y2internal("Cannot find yast module.");
    return Qnil;
  }

  VALUE yast = rb_define_module("Yast");
  VALUE cls = rb_const_get(yast, rb_intern("External"));
  VALUE tdata = Data_Wrap_Struct(cls, 0, rb_ext_free, new YCPExternal(ext));
  VALUE argv[] = {yrb_utf8_str_new(ext->magic())};
  rb_obj_call_init(tdata, 1, argv);
  return tdata;
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
  if (ycpval.isNull() || ycpval->isVoid())
  {
    return Qnil;
  }
  else if (ycpval->isBoolean())
  {
    return ycpval->asBoolean()->value() ? Qtrue : Qfalse;
  }
  else if (ycpval->isString())
  {
    // always use UTF-8 encoding
    return yrb_utf8_str_new(ycpval->asString()->value());
  }
  else if (ycpval->isPath())
  {
    return ycp_path_to_rb_path(ycpval->asPath());
  }
  else if (ycpval->isTerm())
  {
    return ycp_term_to_rb_term(ycpval->asTerm());
  }
  else if (ycpval->isInteger())
  {
    return LL2NUM( ycpval->asInteger()->value() );
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
    YCPList list = ycpval->asList();
    rblist = rb_ary_new2(list.size());
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
    return ID2SYM(rb_intern(symbol->symbol_cstr()));
  }
  else if (ycpval->isReference())
  {
    return ycp_ref_to_rb_ref(ycpval->asReference());
  }
  else if (ycpval->isExternal())
  {
    return ycp_ext_to_rb_ext(ycpval->asExternal());
  }
  else if (ycpval->isCode())
  {
    return ycp_code_to_rb_code(ycpval->asCode());
  }
  else if (ycpval->isByteblock())
  {
    return ycp_bb_to_rb_bb(ycpval->asByteblock());
  }
  rb_raise( rb_eTypeError, "Conversion of YCP type '%s': %s not supported", Type::vt2type(ycpval->valuetype())->toString().c_str(), ycpval->toString().c_str() );
  return Qnil;
}


