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
#include <ycp/YCPSymbol.h>

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
  YCPList client_arglist = arglist;

  // YCP debugger hack: look only at the last entry, if it's debugger or not
  // and remove it, see Y2WFMComponent::doActualWork() in
  // https://github.com/yast/yast-core/blob/master/wfm/src/Y2WFMComponent.cc#L143
  if (!client_arglist->isEmpty())
  {
      YCPValue last = client_arglist->value(client_arglist->size() - 1);
      if (last->isSymbol () && last->asSymbol()->symbol() == "debugger")
      {
          y2milestone("Removing `debugger symbol from the argument list");

          // remove the flag from the arguments
          client_arglist->remove(arglist->size() - 1);
      }
  }

  y2debug( "Call client with args %s", client_arglist->toString().c_str());
  YCPList old_args = Y2WFMComponent::instance()->SetArgs(client_arglist);
  YCPValue res = YRuby::yRuby()->callClient(client);
  Y2WFMComponent::instance()->SetArgs(old_args);
  return res;
}
