#include <unistd.h>
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
  y2debug("look for client with name %s", name);
  string sname(name);
  string client_path = YCPPathSearch::find (YCPPathSearch::Client, sname + ".rb");
  //client not found in form clients/<name>.rb
  if (client_path.empty())
  {
    // for paths it needs at least one slash BNC#330965#c10
    if(!strchr (name, '/'))
      return NULL;

    client_path = Y2PathSearch::completeFilename (sname);
    if (client_path.empty())
      return NULL;

    if (strlen(name) > 3 && strcmp(name + strlen(name) - 3, ".rb")) //not ruby file
      return NULL;
  }

  y2debug("test existence of file %s", client_path.c_str());
  if (access(client_path.c_str(), R_OK) == -1) //no file or no read permission
    return NULL;

  Y2RubyClientComponent* rc = Y2RubyClientComponent::instance();
  rc->setClient(client_path);
  return rc;
}

