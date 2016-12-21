#include <vector>
#include <string>

#include <ruby.h>
#include <ruby/encoding.h>

#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>

#include "y2util/stringutil.h"
#include "Y2RubyUtils.h"

using namespace std;

bool y2_require(const char *str)
{
  int error;
  rb_protect( (VALUE (*)(VALUE))rb_require, (VALUE) str, &error);
  if (error)
  {
    VALUE exception = rb_errinfo(); /* get last exception */
    // do not clear exception yet, as it can be also processed later
    VALUE reason = rb_funcall(exception, rb_intern("message"), 0 );
    VALUE trace = rb_funcall(exception, rb_intern("backtrace"), 0 );
    VALUE backtrace = RARRAY_LEN(trace)>0 ? rb_ary_entry(trace, 0) : rb_str_new2("Unknown");
    y2error("cannot require yast:%s at %s", StringValuePtr(reason),StringValuePtr(backtrace));
    return false;
  }

  return true;
}

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

VALUE yrb_utf8_str_new(const std::string &str) {
  if (!utf8)
    utf8 = rb_enc_find("UTF-8");

  return rb_enc_str_new(str.c_str(), str.size(), utf8);
}

VALUE yrb_utf8_str_new(const char *str) {
  if (!utf8)
    utf8 = rb_enc_find("UTF-8");

  return rb_enc_str_new(str, strlen(str), utf8);
}

