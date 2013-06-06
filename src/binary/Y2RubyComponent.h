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

#ifndef Y2RubyComponent_h
#define Y2RubyComponent_h

#include "Y2.h"
#include <string.h>
#include "map"


/**
 * @short YaST2 Component: Ruby bindings
 */
class Y2RubyComponent : public Y2Component
{
private:
    std::map<std::string, Y2Namespace*> namespaces;

public:
    /**
     * Constructor.
     */
    Y2RubyComponent();

    /**
     * Destructor.
     */
    ~Y2RubyComponent();

    /**
     * The name of this component.
     */
    string name() const { return "ruby"; }

    /**
     * Is called by the generic frontend when the session is finished.
     */
    void result( const YCPValue & result );

    /**
     * Implements the Ruby:: functions.
     **/
// not yet, prototype the transparent bindings first
//    YCPValue evaluate( const YCPValue & val );

    /**
     * Try to import a given namespace. This method is used
     * for transparent handling of namespaces (YCP modules)
     * through whole YaST.
     * @param name_space the name of the required namespace
     * @return on errors, NULL should be returned. The
     * error reporting must be done by the component itself
     * (typically using y2log). On success, the method
     * should return a proper instance of the imported namespace
     * ready to be used. The returned instance is still owned
     * by the component, any other part of YaST will try to
     * free it. Thus, it's possible to share the instance.
     */
    Y2Namespace *import (const char* name);

    /**
     * Utility method to translate camelcase name of module to delimeter
     * separated one. It is useful for loading modules which follows conventions
     * so ActiveSupport namespace is from active_support.rb.
     */
    static const std::string CamelCase2DelimSepated (const char* name);
};

#endif	// Y2RubyComponent_h
