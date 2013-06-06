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

#define y2log_component "Y2RubyClient"
#include <ycp/y2log.h>
#include <ycp/pathsearch.h>

#include "Y2RubyClientComponent.h"
#include "YRuby.h"
#include "wfm/Y2WFMComponent.h"
using std::string;

Y2RubyClientComponent* Y2RubyClientComponent::_instance = NULL;

Y2RubyClientComponent::Y2RubyClientComponent()
{
}

Y2RubyClientComponent::~Y2RubyClientComponent()
{
  y2debug( "Destroying Y2RubyClientComponent" );
}

Y2RubyClientComponent* Y2RubyClientComponent::instance()
{
  if (_instance == NULL)
    _instance = new Y2RubyClientComponent();

  return _instance;
}


YCPValue Y2RubyClientComponent::doActualWork(const YCPList& arglist,
    Y2Component *displayserver)
{
  y2debug( "Call client with args %s", arglist->toString().c_str());
  YCPList old_args = Y2WFMComponent::instance()->SetArgs(arglist);
  YCPValue res = YRuby::yRuby()->callClient(client);
  Y2WFMComponent::instance()->SetArgs(old_args);
  return res;
}
