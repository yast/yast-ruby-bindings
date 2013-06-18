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

#ifndef RubyLogger_h
#define RubyLogger_h

#include "ycp/y2log.h"

/**
 * @short A class to provide logging for Ruby bindings errors and warning
 */
class RubyLogger : public Logger
{
    static RubyLogger* m_rubylogger;

public:
    void error (string message);
    void warning (string message);

    static RubyLogger* instance ();
};

#endif	// ifndef RubyLogger_h


// EOF
