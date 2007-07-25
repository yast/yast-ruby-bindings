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

#include <stdlib.h>
#include <list>
#include <iosfwd>
#include <sstream>
#include <iomanip>

// Ruby stuff
#include <ruby.h>


#define y2log_component "Y2Ruby"
#include <ycp/y2log.h>
#include <ycp/pathsearch.h>


#include <ycp/YCPBoolean.h>
#include <ycp/YCPByteblock.h>
#include <ycp/YCPFloat.h>
#include <ycp/YCPInteger.h>
#include <ycp/YCPList.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPPath.h>
#include <ycp/YCPString.h>
#include <ycp/YCPSymbol.h>
#include <ycp/YCPTerm.h>
#include <ycp/YCPVoid.h>
#include <ycp/YCPCode.h>
#include <ycp/YCPExternal.h>

#include "YRuby.h"

#define DIM(ARRAY)	( sizeof( ARRAY )/sizeof( ARRAY[0] ) )

#include "Y2RubyTypeConv.h"

static void prependModulePath()
{
  YCPPathSearch::initialize ();

  list<string>::const_iterator
      b = YCPPathSearch::searchListBegin (YCPPathSearch::Module),
      e = YCPPathSearch::searchListEnd (YCPPathSearch::Module),
      i;
      
  // count the number of directories to prepend
//   int n = 0;
//   for (i = b; i != e; ++i)
//   {
//     // do something
//   }
}

YRuby * YRuby::_yRuby = 0;

YRuby::YRuby()
{
  y2milestone( "Initializing ruby interpreter." );
  ruby_init();
  //ruby_options(argc - 1, ++argv);
  ruby_script("yast");
  ruby_init_loadpath();
}

YRuby::~YRuby()
{
    y2milestone( "Shutting down ruby interpreter." );
    ruby_finalize();
}


YRuby *
YRuby::yRuby()
{
  if ( ! _yRuby )
    _yRuby = new YRuby();

  return _yRuby;
}


YCPValue
YRuby::destroy()
{
  if ( _yRuby )
    delete _yRuby;

  _yRuby = 0;

  return YCPVoid();
}

/**
 * Loads a module.
 */
YCPValue
YRuby::loadModule( YCPList argList )
{
  YRuby::yRuby();
  //y2milestone("loadModule 1");
  if ( argList->size() != 2 || ! argList->value(0)->isString() || ! argList->value(1)->isString() )
    return YCPError( "Ruby::loadModule() / Ruby::Use() : Bad arguments: String expected!" );
  //y2milestone("loadModule 2");
  string module_name = argList->value(0)->asString()->value();
  string module_path = argList->value(1)->asString()->value();
  //y2milestone("loadModule 3: '%s'", module_name.c_str());
  string require_module = "require(\"" + module_path + "\")";
  //y2milestone("loadModule 3.5");
  VALUE result = rb_eval_string((require_module).c_str());
  if ( result == Qfalse )
    return YCPError( "Ruby::loadModule() / Can't load ruby module '" + module_path + "'" );
  //y2milestone("loadModule 4");
  return YCPVoid();
}



/**
 * @param argList arguments start 1!, 0 is dummy
 */
YCPValue
YRuby::callInner (string module_name, string function, bool method,
                  YCPList argList, constTypePtr wanted_result_type)
{
  VALUE module = rb_funcall( rb_mKernel, rb_intern("const_get"), 1, rb_str_new2(module_name.c_str()) );
  if (module == Qnil)
  {
    y2error ("The Ruby module '%s' is not provided by its rb file", module_name.c_str());
    return YCPVoid();
  }
  
  // first element of the list is ignored
  int size = argList.size();
  
  // make rooms for size-1 arguments to
  // the ruby function
  VALUE values[size-1];
  int i=0;
  for ( ; i < size-1; ++i )
  {
    // get the
    YCPValue v = argList->value(i+1);
    y2milestone("Adding argument %d of type %s", i, v->valuetype_str());
    values[i] = ycpvalue_2_rbvalue(v);
  }

  y2milestone( "Wll call function '%s' in module '%s' with '%d' arguments", function.c_str(), module_name.c_str(), size-1);
  VALUE result = rb_funcall2( module, rb_intern(function.c_str()), size-1, values );
  //VALUE result = rb_funcall( module, rb_intern(function.c_str()), 2, INT2NUM(2), INT2NUM(3) );
  y2milestone( "Called function '%s' in module '%s'", function.c_str(), module_name.c_str());
  return rbvalue_2_ycpvalue(result);
}

