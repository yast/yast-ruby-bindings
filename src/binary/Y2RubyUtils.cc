#include <vector>
#include <string>

#include <ruby.h>
#include <ruby/encoding.h>

#include "y2util/stringutil.h"
#include "Y2RubyUtils.h"

using namespace std;

// cache the UTF-8 encoding object
static rb_encoding *utf8;

static VALUE const_get_wrapper(VALUE input)
{
  VALUE *data = (VALUE*) input;
  return rb_const_get(data[0], data[1]);
}

VALUE y2ruby_nested_const_get(const std::string &name)
{
  // to save every component of Foo::Bar::Ehh
  vector<string> name_levels;
  stringutil::split( name, name_levels, "::", false);
  VALUE module = rb_cObject;


  for ( unsigned i = 0; i < name_levels.size(); ++i ) {
      int error = 0;
      // tricky part as rb_protect takes only one param, so get to it more of them
      VALUE data[2];
      data[0] = module;
      data[1] = rb_intern(name_levels[i].c_str());
      module = rb_protect(const_get_wrapper, (VALUE)data, &error );
      if ( error )
        return Qnil;
  }
  return module;
}

VALUE rb_utf8_str_new(const std::string &str) {
  if (!utf8)
    utf8 = rb_enc_find("UTF-8");

  return rb_enc_str_new(str.c_str(), str.size(), utf8);
}

VALUE rb_utf8_str_new(const char *str) {
  if (!utf8)
    utf8 = rb_enc_find("UTF-8");

  return rb_enc_str_new(str, strlen(str), utf8);
}

