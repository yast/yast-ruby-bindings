#include <vector>
#include <string>

#include "y2util/stringutil.h"
#include "Y2RubyUtils.h"

using namespace std;

VALUE y2ruby_nested_const_get(const std::string &name)
{
  VALUE module = rb_mKernel;  
  // to save every component of Foo::Bar::Ehh
  vector<string> name_levels;
  stringutil::split( name, name_levels, "::", false);
  
  for ( unsigned i = 0; i < name_levels.size(); ++i ) {
      module = rb_funcall( module, rb_intern("const_get"), 1, rb_str_new2(name_levels[i].c_str()) );
  }
  return module;    
}
