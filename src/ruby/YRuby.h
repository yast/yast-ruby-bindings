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
    
protected:
    
public:
    static YRuby *	_yRuby;
};

#endif	// YRuby_h
