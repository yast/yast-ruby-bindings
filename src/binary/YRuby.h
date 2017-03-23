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

class YRuby
{
public:

    /**
     * Load a Ruby module - equivalent to "require" in Ruby.
     *
     * Returns a YCPError on failure, YCPVoid on success.
     **/
    static bool loadModule( YCPList argList );

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
     **/
    static void destroy();


protected:

    /**
     * Protected constructor. Use one of the static methods rather than
     * instantiate an object of this class yourself.
     **/
    YRuby();

    /**
     * Destructor.
     **/
    ~YRuby();

public:
    /**
     * Generic Ruby call.
     **/
    YCPValue callInner (string module, string function, YCPList argList,
      constTypePtr wanted_result_type);
    /**
     * Ruby VALUEs do not have a reference count like YCP or Perl.
     * To protect them from being garbage-collected, they must be marked
     * via ruby_gc_mark
     *
     * A set is not enough: one VALUE can be referenced by multiple
     * YCPValueReps
     */
    typedef std::map<VALUE, int> refcount_map_t;

    /**
     * Generic call to clients written in ruby
     */
    YCPValue callClient (const string& path);

private:
    static void gc_mark(void *object);
    static void gc_free(void *object);

public:
    static YRuby *	_yRuby;
    static bool  _y_ruby_finalized;
    static bool  _y_in_yast;
    refcount_map_t value_references_from_ycp;
};

#endif	// YRuby_h
