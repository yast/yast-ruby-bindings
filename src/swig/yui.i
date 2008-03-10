%module yuix

%{
#include <yui/YUI.h>
%}
%ignore start_ui_thread;
%include <yui/YUI.h>
