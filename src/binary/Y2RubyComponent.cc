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
#include <y2/Y2Namespace.h>

#include "Y2RubyComponent.h"
#include "YRuby.h"
#include "YRubyNamespace.h"
using std::string;
using std::map;


Y2RubyComponent::Y2RubyComponent()
{
}


Y2RubyComponent::~Y2RubyComponent()
{
  for( map<string,Y2Namespace*>::iterator i = namespaces.begin(); i != namespaces.end(); ++i)
  {
    delete i->second;
  }
  y2debug( "Destroying Y2RubyComponent" );
  YRuby::destroy();
}


void Y2RubyComponent::result( const YCPValue & )
{}


Y2Namespace *Y2RubyComponent::import (const char* name)
{

  map<string,Y2Namespace*>::iterator cached_namespace = namespaces.find(name);
  if (cached_namespace != namespaces.end())
    return cached_namespace->second;

  y2debug("Creating namespace for import '%s'", name);
  // must be the same in Y2CCRuby and Y2RubyComponent
  string module = YCPPathSearch::find (YCPPathSearch::Module, string (name) + ".rb");
  if (module.empty ())
  {
    module = YCPPathSearch::find (YCPPathSearch::Module, Y2RubyComponent::CamelCase2DelimSepated(name) + ".rb");
    if (module.empty ())
    {
      y2internal ("Couldn't find %s after Y2CCRuby pointed to us", name);
      return NULL;
    }
  }
  y2debug("Found in '%s'", module.c_str());
  module.erase (module.size () - 3 /* strlen (".rb") */);
  YCPList args;
  args->add (YCPString(/*module*/ name));
  args->add (YCPString(/*module*/ module));

  try
  {
    if (YRuby::loadModule (args))
    {
      y2debug("Module '%s' loaded", name);
      // introspect, create data structures for the interpreter
      Y2Namespace * res = new YRubyNamespace (name);
      namespaces[name] = res;
      return res;
    }
    else // report more verbose why require failed
    {
      VALUE exception = rb_errinfo(); /* get last exception */
      rb_set_errinfo(Qnil); // clear exception, so we can recover from it
      VALUE reason = rb_funcall(exception, rb_intern("message"), 0 );
      VALUE trace = rb_funcall(exception, rb_intern("backtrace"), 0 );
      VALUE trace_to_s = rb_funcall(trace, rb_intern("join"), 1,  rb_str_new_cstr("\n"));
      string reason_s(StringValuePtr(reason));
      string trace_s(StringValuePtr(trace_to_s));

      y2error("Reporting runtime error for import of module '%s' message '%s'",
        name, reason_s.c_str());

      Y2Namespace * res = new Y2ErrorNamespace (reason_s, trace_s);
      namespaces[name] = res;
      return res;
    }
  } catch (std::exception& e) {
    y2error("Reporting runtime error for import of module '%s' message '%s'",
        name, e.what());
    // use empty trace, as we cannot get location of issue in module
    Y2Namespace * res = new Y2ErrorNamespace (e.what(), "");
    namespaces[name] = res;
    return res;
  }
}

const string Y2RubyComponent::CamelCase2DelimSepated( const char* name)
{
  string res = name;
  size_t size = res.size();
  if (size==0)
    return res;
  // convert always in C locale (bnc#852242)
  char *old_locale = strdup(setlocale(LC_ALL, NULL));
  setlocale(LC_ALL, "C");
  res[0] = tolower(res[0]);
  //first character and first char after :: is lowercase without underscore
  for(size_t i = res.find("::"); i!= string::npos; i = res.find("::",i+1))
  {
    size_t c_pos = i+2; //::<c> so we want c
    if (c_pos >= size) break; //handle string finishing with ::
    res[c_pos] = tolower(res[c_pos]);
  }
  for (size_t i = 1; i< res.size();i++)
  {
    if (isupper(res[i]))
    {
      string tmp = "_";
      tmp.push_back (tolower(res[i]));
      res.replace(i,1,tmp); //replace upper by _lower
    }
  }
  setlocale(LC_ALL, old_locale);
  free(old_locale);
  return res;
}
