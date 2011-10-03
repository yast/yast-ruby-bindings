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

#ifndef YRuby_h
#define YRuby_h

// Ruby stuff
#include <ruby.h>

#include <ycp/YCPList.h>
#include <ycp/Type.h>

// make the compiler happy when
// calling rb_define_method()
typedef VALUE (ruby_method)(...);

// more useful macros
#define RB_FINALIZER(func) ((void (*)(...))func)

// this macro saves us from typing
// (ruby_method*) & method_name
// in rb_define_method
#define RB_METHOD(func) ((VALUE (*)(...))func)

class YRuby
{
public:

    /**
     * Load a Ruby module - equivalent to "use" in Ruby.
     *
     * Returns a YCPError on failure, YCPVoid on success.
     **/
    static YCPValue loadModule( YCPList argList );

    /**
     * Access the static (singleton) YRuby object. Create it if it isn't
     * created yet.
     *
     * Returns 0 on error.
     **/
    static YRuby * yRuby();

    /**
     * Destroy the static (singleton) YRuby object and unload the embedded Ruby
     * interpreter.
     *
     * Returns YCPVoid().
     **/
    static YCPValue destroy();

    
protected:

    /**
     * Protected constructor. Use one of the static methods rather than
     * instantiate an object of this class yourself.
     **/
    YRuby();

    /**
     * Protected constructor. Use one of the static methods rather than
     * instantiate an object of this class yourself.
     **/
    
    /**
     * Destructor.
     **/
    ~YRuby();

    /**
     * Returns the internal embedded Ruby interpreter.
     **/


public:
    /**
     * Generic Ruby call.
     **/
    YCPValue callInner (string module, string function, bool method,
			YCPList argList, constTypePtr wanted_result_type);
    /**
     * Ruby VALUEs do not have a reference count like YCP or Perl.
     * To protect them from being garbage-collected, they must be marked
     * via ruby_gc_mark
     *
     * A set is not enough: one VALUE can be referenced by multiple
     * YCPValueReps
     */
    typedef std::map<VALUE, int> refcount_map_t;
    
private:
    static void gc_mark(void *object);
    static void gc_free(void *object);

public:
    static YRuby *	_yRuby;
    refcount_map_t value_references_from_ycp;
};

#endif	// YRuby_h
