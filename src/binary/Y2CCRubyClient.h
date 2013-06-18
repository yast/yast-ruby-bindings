#ifndef _Y2CCRubyClient_h
#define _Y2CCRubyClient_h

#include "Y2RubyClientComponent.h"

/**
 * @short Y2ComponentCreator that creates Ruby client component
 *
 * A Y2ComponentCreator is an object that can create components.
 * It receives a component name and - if it knows how to create
 * such a component - returns a newly created component of this
 * type. Y2CCRubyClient can create components with the name "RubyClient".
 */
class Y2CCRubyClient : public Y2ComponentCreator
{
private:
    Y2Component *cruby;

public:
    /**
     * Creates a Ruby component creator
     */
    Y2CCRubyClient() : Y2ComponentCreator( Y2ComponentBroker::BUILTIN ),
	cruby (0) {};

    ~Y2CCRubyClient () {
	if (cruby)
	    delete cruby;
    }

    /**
     * Returns true, since the Ruby component is a YaST2 server.
     */
    bool isServerCreator() const { return false; };

    /**
     * Creates a new Ruby component.
     */
    Y2Component *create( const char * name ) const;

    /**
     * always returns the same component, deletes it finally
     */
    Y2Component *provideNamespace (const char *name);

};

#endif
