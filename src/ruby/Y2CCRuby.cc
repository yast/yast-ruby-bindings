#include "Y2CCRuby.h"
#include <ycp/pathsearch.h>
#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>

// This is very important: We create one global variable of
// Y2CCRuby. Its constructor will register it automatically to
// the Y2ComponentBroker, so that will be able to find it.
// This all happens before main() is called!

Y2CCRuby g_y2ccruby;

Y2Component *Y2CCRuby::provideNamespace (const char *name)
{
  y2debug ("Y2CCRuby::provideNamespace %s", name);
  if (strcmp (name, "Ruby") == 0)
  {
    // low level functions

    // leave implementation to later
    return 0;
  }
  else
  {
    // is there a ruby module?
    // must be the same in Y2CCRuby and Y2RubyComponent
    string module = YCPPathSearch::find (YCPPathSearch::Module, string (name) + ".rb");
    y2milestone("Find result '%s'", module.c_str());
    if (!module.empty ())
    {
      if (!cruby)
      {
        y2milestone("new ruby component");
        cruby = new Y2RubyComponent();
      }
      y2milestone("returning existing ruby component");
      return cruby;
    }

    // let someone else try creating the namespace
    return 0;
  }
}
