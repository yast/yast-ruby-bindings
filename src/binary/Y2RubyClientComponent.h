#ifndef Y2RubyClientComponent_h
#define Y2RubyClientComponent_h

#include "Y2.h"
#include <string.h>


/**
 * @short YaST2 Component: Ruby bindings
 */
class Y2RubyClientComponent : public Y2Component
{
public:
    /**
     * Destructor.
     */
    ~Y2RubyClientComponent();

    static Y2RubyClientComponent* instance();

    void setClient(const string& _client) { client = _client; }

    /**
     * The name of this component.
     */
    string name() const { return "rubyclient"; }

    YCPValue doActualWork(const YCPList& arglist, Y2Component *displayserver);

private:
    string client;
    static Y2RubyClientComponent* _instance;

    /**
     * Constructor.
     */
    Y2RubyClientComponent();

};

#endif	// Y2RubyComponent_h
