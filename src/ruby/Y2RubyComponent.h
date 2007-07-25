#ifndef Y2RubyComponent_h
#define Y2RubyComponent_h

#include "Y2.h"


/**
 * @short YaST2 Component: Ruby bindings
 */
class Y2RubyComponent : public Y2Component
{
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
    string name() const { return "perl"; }

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
};

#endif	// Y2RubyComponent_h
