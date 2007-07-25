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

#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>
#include <ycp/pathsearch.h>

#include "Y2RubyComponent.h"
#include "YRuby.h"
#include "YRubyNamespace.h"
using std::string;


Y2RubyComponent::Y2RubyComponent()
{
  // Actual creation of a Ruby interpreter is postponed until one of the
  // YRuby static methods is used. They handle that.

  y2milestone( "Creating Y2RubyComponent" );
}


Y2RubyComponent::~Y2RubyComponent()
{
  y2milestone( "Destroying Y2RubyComponent" );
  YRuby::destroy();
}


void Y2RubyComponent::result( const YCPValue & )
{}


Y2Namespace *Y2RubyComponent::import (const char* name)
{
  y2milestone("Creating namespace for import '%s'", name);
  // TODO where to look for it
  // must be the same in Y2CCRuby and Y2RubyComponent
  string module = YCPPathSearch::find (YCPPathSearch::Module, string (name) + ".rb");
  if (module.empty ())
  {
    y2internal ("Couldn't find %s after Y2CCRuby pointed to us", name);
    return NULL;
  }
  y2milestone("Found in '%s'", module.c_str());
  module.erase (module.size () - 3 /* strlen (".pm") */);
  YCPList args;
  args->add (YCPString(/*module*/ name));
  args->add (YCPString(/*module*/ module));
  // load it
  YRuby::loadModule (args);
  y2milestone("Module '%s' loaded", name);
  // introspect, create data structures for the interpreter
  Y2Namespace *ns = new YRubyNamespace (name);

  return ns;
}
