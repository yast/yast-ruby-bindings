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
