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
#include <stdarg.h>
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
#include "Y2RubyUtils.h"

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

  VALUE ycp_references = Data_Wrap_Struct(rb_cObject, gc_mark, gc_free, & value_references_from_ycp);
  rb_global_variable(&ycp_references);
}

void YRuby::gc_mark(void *object)
{
  refcount_map_t * vrby = (refcount_map_t *) object;

  y2internal("mark: map size is %u", vrby->size());
  refcount_map_t::iterator
    b = vrby->begin(),
    e = vrby->end(),
    it;
  for (it = b; it != e; ++it) {
    y2internal("marking: value %ld refcount %d", it->first, it->second);
    rb_gc_mark(it->first);
  }
}

void YRuby::gc_free(void *object)
{
  refcount_map_t * vrby = (refcount_map_t *) object;

  y2internal("free: map size is %u", vrby->size());
  y2internal("should happen quite last or we are in trouble FIXME");
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
  VALUE result = rb_require(module_path.c_str());
  if ( result == Qfalse )
    return YCPError( "Ruby::loadModule() / Can't load ruby module '" + module_path + "'" );
  //y2milestone("loadModule 4");
  return YCPVoid();
}


// snprintf into a temp string
static char *
fmtstr(const char* fmt, ...)
{
    va_list ap; 
    int len; 
    char* str;

    va_start(ap, fmt); 
    len = vsnprintf(NULL, 0, fmt, ap); 
    va_end(ap); 
    if (len <= 0)
    {
        return NULL; 
    }
    str = (char*)malloc(len+1); 
    if (str == NULL)
    {
        return NULL; 
    }
    va_start(ap, fmt); 
    vsnprintf(str, len+1, fmt, ap); 
    va_end(ap); 
    return str; 
}


// rb_protect-enabled rb_funcall, see below
static VALUE
protected_call(VALUE args)
{
  VALUE *values = (VALUE *)args;
  return rb_funcall3(values[0], values[1], (int)values[2], values+3);	
}

/**
 * @param argList arguments start 1!, 0 is dummy
 */
YCPValue
YRuby::callInner (string module_name, string function, bool method,
                  YCPList argList, constTypePtr wanted_result_type)
{
  RUBY_INIT_STACK  // bnc#708059
  VALUE module = y2ruby_nested_const_get(module_name);
  if (module == Qnil)
  {
    y2error ("The Ruby module '%s' is not provided by its rb file", module_name.c_str());
    return YCPVoid();
  }
  
  // first element of the list is ignored
  int size = argList.size();
  
  // make rooms for size-1 arguments to
  // the ruby function
  // +3 for module, function, and number of args
  // to pass to protected_call()
  VALUE values[size-1+3];
  int error;
  int i=0;
  for ( ; i < size-1; ++i )
  {
    // get the
    YCPValue v = argList->value(i+1);
    y2milestone("Adding argument %d of type %s", i, v->valuetype_str());
    values[i+3] = ycpvalue_2_rbvalue(v);
  }

  y2milestone( "Will call function '%s' in module '%s' with '%d' arguments", function.c_str(), module_name.c_str(), size-1);
  values[0] = module;
  values[1] = rb_intern(function.c_str());
  values[2] = size-1;
  VALUE result = rb_protect(protected_call, (VALUE)values, &error);
  if (error)
  {
    VALUE exception = rb_gv_get("$!"); /* get last exception */
    VALUE reason = rb_funcall(exception, rb_intern("message"), 0 );
    VALUE trace = rb_gv_get("$@"); /* get last exception trace */
    VALUE backtrace = rb_funcall(trace, rb_intern("join"), 1, rb_str_new("\n\t", 2));

    char* tmp = fmtstr("%s\n\t%s", StringValuePtr(reason), StringValuePtr(backtrace)); 
    y2error("%s.%s failed\n%s", module_name.c_str(), function.c_str(), tmp);
    //workaround if last_exception failed, then return always string with message
    if(function == "last_exception") //TODO constantify last_exception
    {
      return YCPString(StringValuePtr(reason));
    }
    return YCPVoid();
  }
  else
  {
  //VALUE result = rb_funcall( module, rb_intern(function.c_str()), 2, INT2NUM(2), INT2NUM(3) );
    y2milestone( "Called function '%s' in module '%s'", function.c_str(), module_name.c_str());
  }
  return rbvalue_2_ycpvalue(result);
}

