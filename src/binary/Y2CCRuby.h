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

#ifndef _Y2CCRuby_h
#define _Y2CCRuby_h

#include "Y2RubyComponent.h"

/**
 * @short Y2ComponentCreator that creates Ruby-from-YCP bindings.
 *
 * A Y2ComponentCreator is an object that can create components.
 * It receives a component name and - if it knows how to create
 * such a component - returns a newly created component of this
 * type. Y2CCRuby can create components with the name "Ruby".
 */
class Y2CCRuby : public Y2ComponentCreator
{
private:
    Y2Component *cruby;

public:
    /**
     * Creates a Ruby component creator
     */
    Y2CCRuby();

    ~Y2CCRuby () {
	if (cruby)
	    delete cruby;
    }

    /**
     * Returns true, since the Ruby component is a YaST2 server.
     */
    bool isServerCreator() const { return true; };

    /**
     * Creates a new Ruby component.
     */
    Y2Component *create( const char * name ) const
    {
	// create as many as requested, they all share the static YRuby anyway
	if ( ! strcmp( name, "ruby") ) return new Y2RubyComponent();
	else return 0;
    }

    /**
     * always returns the same component, deletes it finally
     */
    Y2Component *provideNamespace (const char *name);

};

#endif	// ifndef _Y2CCRuby_h


// EOF
