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
