#include "Y2CCRubyClient.h"
#include <ycp/pathsearch.h>
#define y2log_component "Y2RubyClient"
#include <ycp/y2log.h>

// This is very important: We create one global variable of
// Y2CCRubyClient. Its constructor will register it automatically to
// the Y2ComponentBroker, so that will be able to find it.
// This all happens before main() is called!

Y2CCRubyClient g_y2ccrubyclient;

Y2Component *Y2CCRubyClient::provideNamespace (const char *name)
{
  // let someone else try creating the namespace, we just provide clients
  return 0;
}

Y2Component *Y2CCRubyClient::create ( const char * name) const
{
  string client_path = YCPPathSearch::find (YCPPathSearch::Client, string (name) + ".rb");
  //client is not in ruby
  if (client_path.empty())
    return NULL;

  Y2RubyClientComponent* rc = Y2RubyClientComponent::instance();
  rc->setClient(client_path);
  return rc;
}

