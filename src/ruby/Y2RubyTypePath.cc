#include "YRuby.h"
#include "Y2RubyTypePath.h"
#include <ycp/YCPPath.h>

static VALUE ryast_cPath;

struct ryast_Path_Wrapper
{
  YCPPath path;
};

//-----------------------------------------------------------------------------
// internal used only

static void
ryast_path_set_path( VALUE self, const YCPPath & path )
{
  ryast_Path_Wrapper *wrapper;
  Data_Get_Struct(self, ryast_Path_Wrapper, wrapper);
  wrapper->path = path;
}

static void
ryast_path_mark (ryast_Path_Wrapper *r)
{

}

static void
ryast_path_free (ryast_Path_Wrapper *r)
{
  delete r;
}

static VALUE
ryast_path_initialize( int argc, VALUE *argv, VALUE self )
{
    ryast_Path_Wrapper *wrapper;
    Data_Get_Struct(self, ryast_Path_Wrapper, wrapper);
    
    // we should be using rb_scan_args here but I couldn't get it to work.

//     if (argc > 0) {
//   Check_Type( argv[0], T_STRING);
//   version = StringValuePtr( argv[0] );
//     }
//     if (argc > 1) {
//   Check_Type( argv[1], T_STRING);
//   release = StringValuePtr( argv[1] );
//     }
//     if (argc > 2) {
//   Check_Type( argv[2], T_FIXNUM);
//   epoch = FIX2INT( argv[2] );
//     }
    wrapper->path = YCPPath();
    return self;
}


static VALUE
ryast_path_allocate(VALUE klass)
{
  // create struct
  ryast_Path_Wrapper *wrapper = new ryast_Path_Wrapper();
  // wrap and return struct
  return Data_Wrap_Struct (klass, ryast_path_mark, ryast_path_free, wrapper);
}

void
ryast_path_init( VALUE super )
{
  ryast_cPath = rb_define_class_under( super, "Path", rb_cObject );
  rb_define_alloc_func( ryast_cPath, ryast_path_allocate );
  rb_define_method( ryast_cPath, "initialize", RB_METHOD( ryast_path_initialize ), -1 );
}
