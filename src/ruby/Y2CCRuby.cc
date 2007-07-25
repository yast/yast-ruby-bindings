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
