#include <vector>
#include <string>

#include "y2util/stringutil.h"
#include "Y2RubyUtils.h"

using namespace std;

static VALUE const_get_wrapper(VALUE input)
{
  VALUE *data = (VALUE*) input;
  return rb_funcall( data[0], rb_intern("const_get"), 1, data[1]);
}

VALUE y2ruby_nested_const_get(const std::string &name)
{
  VALUE module = rb_mKernel;
  // to save every component of Foo::Bar::Ehh
  vector<string> name_levels;
  stringutil::split( name, name_levels, "::", false);

  for ( unsigned i = 0; i < name_levels.size(); ++i ) {
      int error = 0;
      // tricky part as rb_protect takes only one param, so get to it more of them
      VALUE data[2];
      data[0] = module;
      data[1] = rb_str_new2(name_levels[i].c_str());
      module = rb_protect(const_get_wrapper, (VALUE)data, &error );
      if ( error )
        return Qnil;
  }
  return module;
}
