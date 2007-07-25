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

#include "RubyLogger.h"
#include <ycp/ExecutionEnvironment.h>

extern ExecutionEnvironment ee;

void
RubyLogger::error (string error_message)
{
  y2_logger (LOG_ERROR,"Ruby",ee.filename ().c_str ()
             ,ee.linenumber (),"","%s", error_message.c_str ());
}


void
RubyLogger::warning (string warning_message)
{
  y2_logger (LOG_ERROR,"Ruby",ee.filename ().c_str ()
             ,ee.linenumber (),"","%s", warning_message.c_str ());
}

RubyLogger*
RubyLogger::instance ()
{
  if ( ! m_rubylogger )
  {
    m_rubylogger = new RubyLogger ();
  }
  return m_rubylogger;
}

RubyLogger* RubyLogger::m_rubylogger = NULL;
