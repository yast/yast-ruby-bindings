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

#include "YRuby.h"
#include "Y2RubyTypeConv.h"
#include "Y2RubyTypeTerm.h"
#include <ycp/YCPTerm.h>

static VALUE ryast_cTerm;

struct ryast_Term_Wrapper
{
  ryast_Term_Wrapper()
    : term("init-me")
  {

  }
  YCPTerm term;
};

//-----------------------------------------------------------------------------
// internal used only

static void
ryast_term_set_term( VALUE self, const YCPTerm & term )
{
  ryast_Term_Wrapper *wrapper;
  Data_Get_Struct(self, ryast_Term_Wrapper, wrapper);
  wrapper->term = term;
}

VALUE
ryast_term_from_term( const YCPTerm &term )
{
  VALUE rterm_obj = rb_funcall( ryast_cTerm, rb_intern("new"), 0);
  ryast_term_set_term( rterm_obj, term );
  return rterm_obj;
}

static void
ryast_term_mark (ryast_Term_Wrapper *r)
{

}

static void
ryast_term_free (ryast_Term_Wrapper *r)
{
  delete r;
}

static VALUE
ryast_term_initialize( int argc, VALUE *argv, VALUE self )
{
    ryast_Term_Wrapper *wrapper;
    Data_Get_Struct(self, ryast_Term_Wrapper, wrapper);
    
    // we should be using rb_scan_args here but I couldn't get it to work.

    // we need at least the name to create a YCPTerm
    Check_Type( argv[0], T_STRING);
    wrapper->term = YCPTerm( RSTRING(argv[0])->ptr );
    // add the remaining YCPTerm arguments
    if (argc > 1)
    {
      int i=1;
      for ( ; i<argc; ++i )
      {
        wrapper->term->add(rbvalue_2_ycpvalue(argv[i]));
      }
    }
    return self;
}


static VALUE
ryast_term_allocate(VALUE klass)
{
  // create struct
  ryast_Term_Wrapper *wrapper = new ryast_Term_Wrapper();
  // wrap and return struct
  return Data_Wrap_Struct (klass, ryast_term_mark, ryast_term_free, wrapper);
}

void
ryast_term_init( VALUE super )
{
  ryast_cTerm = rb_define_class_under( super, "Term", rb_cObject );
  rb_define_alloc_func( ryast_cTerm, ryast_term_allocate );
  rb_define_method( ryast_cTerm, "initialize", RB_METHOD( ryast_term_initialize ), -1 );
}
