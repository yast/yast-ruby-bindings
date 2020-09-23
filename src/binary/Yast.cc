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

#include <y2/Y2ComponentCreator.h>

#include <ycp-ui/YUIComponent.h>

#include <y2/Y2ComponentBroker.h>
#include <y2/Y2Namespace.h>
#include <y2/Y2Component.h>
#include <y2/Y2Function.h>

#include <ycp/pathsearch.h>
#include <ycp/y2log.h>
#include <ycp/YExpression.h>
#include <ycp/YCPValue.h>
#include <ycp/YCPVoid.h>
#include <ycp/YCPCode.h>
#include <ycp/YCPSymbol.h>
#include <ycp/YCPMap.h>
#include <ycp/YCPByteblock.h>
#include <ycp/Import.h>
#include <ycp/y2log.h>

#include "ruby.h"

#include "Y2YCPTypeConv.h"
#include "Y2RubyTypeConv.h"
#include "Y2RubyUtils.h"

/*
 * Ruby module anchors
 *
 */
static VALUE rb_mYast;
static VALUE rb_cYReference;
static VALUE rb_cByteblock;
static VALUE rb_cYCode;

extern "C" {

static Y2Namespace *
getNs (const char * ns_name)
{
  Import import(ns_name);  // has a static cache
  Y2Namespace *ns = import.nameSpace();
  if (ns == NULL)
  {
    y2error ("ruby call: Can't import namespace '%s'", ns_name);
  }
  else
  {
    ns->initialize ();
  }
  return ns;
}


/*
 * import_namespace
 *
 * tries to import a namespace
 * throws a NameError if failed
 * throws a RuntimeError with more defails if import get exception during loading
 *
 */
static VALUE
import_namespace( const char *name)
{
  Y2Namespace *ns = getNs(name);
  if (ns == NULL)
  {
    rb_raise( rb_eNameError, "component cannot import namespace '%s'", name );
    return Qnil;
  }

  if (isErrorNamespace(ns))
  {
    Y2ErrorNamespace* ens = toErrorNamespace(ns);
    string message("Failed to load Module '");
    message = message + name + "' due to: " + ens->summary();
    VALUE exception = rb_exc_new2(rb_eRuntimeError, message.c_str());
    VALUE backtrace = rb_str_new_cstr(ens->details().c_str());
    backtrace = rb_funcall(backtrace, rb_intern("split"), 1, rb_str_new_cstr("\n"));
    rb_funcall(exception, rb_intern("set_backtrace"), 1, backtrace);
    rb_exc_raise(exception);
    return Qnil;
  }

  y2debug("namespace created from %s\n", ns->filename().c_str());
  return Qtrue;
}


/*
 * import( name )
 *
 * Tries to import a YCP namespace
 *
 * call-seq:
 *   Yast.import("name")
 *
 */

static VALUE
ycp_module_import( VALUE self, VALUE name)
{
  const char *s = StringValuePtr(name);
  return import_namespace(s);
}

static VALUE
ycp_find_include_file( VALUE self, VALUE path)
{
  string ipath (StringValuePtr(path));
  string include_path = YCPPathSearch::find (YCPPathSearch::Include, ipath);
  if (include_path.empty())
    rb_raise(rb_eRuntimeError, "Cannot find client %s", ipath.c_str());

  return yrb_utf8_str_new(include_path);
}
/*
 * ycp_module_each_symbol(namespace) -> iterator
 *
 * iterates all symbols in a namespace and yields the
 * symbol name and category
 * Internal API only for defining methods for given namespace
 *
 * call-seq:
 *   each_symbol("namespace") { |symbol,category| ... }
 *
 */

static VALUE
ycp_module_symbols(VALUE self, VALUE namespace_name)
{
  const char *name = StringValuePtr(namespace_name);
  Y2Namespace *ns = getNs(name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "error getting namespace '%s'", name );
    return Qnil;
  }

  y2debug("got namespace from %s\n", ns->filename().c_str());

  VALUE res = rb_hash_new();
  for (unsigned int i=0; i < ns->symbolCount(); ++i)
  {
    SymbolEntryPtr s = ns->symbolEntry(i);
    VALUE name = yrb_utf8_str_new(s->name());
    VALUE type = ID2SYM(rb_intern(s->catString().c_str()));
    rb_hash_aset(res,name,type);
  }
  return res;
}

/*
 * set the caller location to log properly the Ruby source location,
 * needs to be called before evaluating any YaST function outside Ruby
 */
void set_ruby_source_location(VALUE file, VALUE lineno)
{
  YaST::ee.setFilename(RSTRING_PTR(file));
  YaST::ee.setLinenumber(FIX2INT(lineno));
}

/**
 * Returns true if the function name is an UI user input function which returns
 * a symbol.
 * @param  function_name name of the function
 * @return true/false
 */
static bool ui_input_function(const char *function_name)
{
    return strcmp(function_name, "UserInput") == 0  ||
        strcmp(function_name, "TimeoutUserInput") == 0 ||
        strcmp(function_name, "PollInput") == 0;
}

/**
 * Returns true if the input symbol starts debugging.
 * @param  val YCPSymbol returned from an UI input call
 * @return true/false
 */
static bool is_debug_symbol(YCPValue val)
{
    return !val.isNull() && val->isSymbol() &&
        val->asSymbol()->symbol() == "debugHotkey";
}

/**
 * Returns true if the function name is an event function returning a map.
 * @param  function_name name of the function
 * @return true/false
 */
static bool ui_event_function(const char *function_name)
{
    return strcmp(function_name, "WaitForEvent") == 0;
}

/**
 * Returns true if the input is a debug UI event.
 * @param  val YCPMap returned from the UI::WaitForEvent call
 * @return true/false
 */
static bool is_debug_event(YCPValue val)
{
    // is it a map?
    if (val.isNull() || !val->isMap())
        return false;

    YCPMap map = val->asMap();

    YCPValue event_type = map->value(YCPString("EventType"));
    // is map["EventType"] == "DebugEvent"?
    if (event_type.isNull() || !event_type->isString() ||
        event_type->asString()->value() != "DebugEvent")
        return false;

    YCPValue event_id = map->value(YCPString("ID"));
    // is map["ID"] == :debugHotkey?
    return !event_id.isNull() && event_id->isSymbol() &&
        event_id->asSymbol()->symbol() == "debugHotkey";
}

/**
 * Start the Ruby debugger, it calls "Yast::Debugger.start" Ruby code.
 * See file ../ruby/yast/debugger.rb for more details.
 */
static void start_ruby_debugger()
{
    y2milestone("Starting the Ruby debugger...");

    rb_require("yast/debugger");
    // call "Yast::Debugger.start"
    VALUE module = rb_const_get(rb_cObject, rb_intern("Yast"));
    VALUE klass = rb_const_get(module, rb_intern("Debugger"));
    rb_funcall(klass, rb_intern("start"), 0);
}

/*
 * call_ycp_function
 *
 * Forwards a ruby call to the namespace
 *
 * First argument is the namespace
 * then function name and arguments
 *
 */

static VALUE
ycp_module_call_ycp_function(int argc, VALUE *argv, VALUE self)
{
  const char *namespace_name = StringValuePtr(argv[0]);
  const char *function_name;
  VALUE symbol = argv[1];

  if (SYMBOL_P(symbol))
    function_name = (const char *)rb_id2name( SYM2ID( symbol ) );
  else
    function_name = StringValuePtr( symbol );

  y2debug("Dynamic Proxy: [%s::%s] with [%d] params\n", namespace_name, function_name, argc);

  Y2Namespace *ns = getNs(namespace_name);
  if (ns == NULL)
  {
    rb_raise( rb_eRuntimeError, "Component cannot import namespace '%s' for symbol '%s'", namespace_name, function_name );
    return Qnil;
  }

  y2debug("Namespace created from %s\n", ns->filename().c_str());

  TableEntry *sym_te = ns->table()->find(function_name);

  if (sym_te == NULL)
  {
    y2internal ("No such symbol %s::%s", namespace_name, function_name);
    rb_raise( rb_eNameError, "YCP symbol '%s' not found in namespace '%s'", function_name, namespace_name );
    return Qnil;
  }

  if (sym_te->sentry ()->isVariable () ||
      sym_te->sentry ()->isReference ())
  {
    y2debug ("Variable or reference %s\n", function_name);
    //get
    if (argc==2)
      return ycpvalue_2_rbvalue(sym_te->sentry()->value());
    // set the variable
    else
    {
      sym_te->sentry()->setValue(rbvalue_2_ycpvalue(argv[2]));
      return argv[2];
    }
  }
  else
  { // no indent yet
    Y2Function* call = ns->createFunctionCall(function_name, 0 /*Type::fromSignature(signature)*/);

    if (call == NULL)
    {
      y2internal ("cannot create function call %s\n", function_name);
      rb_raise( rb_eRuntimeError, "can't create call to %s::%s", namespace_name, function_name);
    }

    y2debug("Call %s", function_name);
    std::map<int,SymbolEntryPtr> refs;
    // add the parameters
    for (int i=4; i < argc; i++)
    {
      YCPValue v = rbvalue_2_ycpvalue(argv[i]);
      y2debug("Append parameter %s", v->toString().c_str());

      const char *class_name = rb_obj_classname(argv[i]);
      //handle args passed by references
      if (!strcmp(class_name, "Yast::ArgRef"))
      {
        refs[i] = v->asReference()->entry();
      }
      call->appendParameter (v);
    }
    call->finishParameters ();

    set_ruby_source_location(argv[2], argv[3]);

    YCPValue res = call->evaluateCall ();
    delete call;
    for (std::map<int,SymbolEntryPtr>::iterator i = refs.begin(); i != refs.end(); ++i)
    {
      //set back reference
      VALUE val = ycpvalue_2_rbvalue(i->second->value());
      RB_GC_GUARD(val);
      rb_funcall(argv[i->first], rb_intern("value="), 1, val);
    }

    // hack: handle the Shift+Ctrl+Alt+D debugging magic key combination
    // returned from UI calls, start the Ruby debugger when the magic key is received
    if (strcmp(namespace_name, "UI") == 0)
    {
        if (
            (ui_input_function(function_name) && is_debug_symbol(res)) ||
            (ui_event_function(function_name) && is_debug_event(res))
        )
        {
          y2milestone("UI::%s() caught magic debug key: %s", function_name, res->toString().c_str());
          start_ruby_debugger();
        }
    }

    return ycpvalue_2_rbvalue(res);
  }
}


/*--------------------------------------------
 *
 * Document-module: Yast
 *
 * The YaST module encloses all Yast related code.
 *
 *--------------------------------------------
 */

//y2_logger_helper

//y2_logger (level, comp, file, line, function, "%s", message);

static VALUE
yast_y2_logger( int argc, VALUE *argv, VALUE self )
{
  Check_Type(argv[0], T_FIXNUM);
  Check_Type(argv[1], T_STRING);
  Check_Type(argv[2], T_STRING);
  Check_Type(argv[3], T_FIXNUM);
  Check_Type(argv[4], T_STRING);

  int i;
  for ( i = 5; i < argc; i++)
  {
    Check_Type(argv[i], T_STRING);
  }
  y2_logger((loglevel_t)FIX2INT(argv[0]), RSTRING_PTR(argv[1]), RSTRING_PTR(argv[2]),
    FIX2INT(argv[3]), RSTRING_PTR(argv[4]), RSTRING_PTR(argv[5]));
  return Qnil;
}

static VALUE
y2dir_paths( VALUE self )
{
  int size = Y2PathSearch::numberOfComponentLevels();
  VALUE result = rb_ary_new2(size);
  for (int i = 0; i < size; ++i)
  {
    rb_ary_push(result, yrb_utf8_str_new(Y2PathSearch::searchPath(Y2PathSearch::GENERIC,i)));
  }
  return result;
}

static VALUE byteblock_to_s(VALUE self)
{
  YCPByteblock *bb;
  Data_Get_Struct(self, YCPByteblock, bb);

  if (bb)
    return yrb_utf8_str_new((*bb)->toString());
  else
    rb_raise(rb_eRuntimeError, "Byteblock is empty");

}

static VALUE ref_call( int argc, VALUE *argv, VALUE self )
{
  SymbolEntry *se;
  Data_Get_Struct(self, SymbolEntry, se);
  if (se->isFunction())
  {
    Y2Function* call = ((Y2Namespace*)(se->nameSpace()))->createFunctionCall(se->name(), se->type());
    // add the parameters
    for (int i=0; i < argc; i++)
    {
      YCPValue v = rbvalue_2_ycpvalue(argv[i]);
      call->appendParameter (v);
    }
    call->finishParameters ();

    YCPValue res = call->evaluateCall ();
    delete call;
    return ycpvalue_2_rbvalue(res);
  }
  else
  {
    rb_raise(rb_eRuntimeError, "Unknown ref type %s", se->toString().c_str());
  }
  return Qnil;
}

static VALUE code_call( int argc, VALUE *argv, VALUE self )
{
  YCPCode *yc;
  Data_Get_Struct(self, YCPCode, yc);
  if (yc)
    return ycpvalue_2_rbvalue((*yc)->evaluate());
  else
    rb_raise(rb_eRuntimeError, "YCode is empty");
}

/*
 * Document-method: ui_component
 *
 * YaST component serving the UI: "gtk", "ncurses", "qt",
 * or the dummy one "UI"
 */
static VALUE ui_get_component()
{
  string s;
  YUIComponent *c = YUIComponent::uiComponent();
  if (c)
  {
    s = c->requestedUIName();
  }
  return yrb_utf8_str_new(s);
}

/*
 * Document-method: ui_component=
 *
 * When Ruby is embedded in YaST (y2base is the main program), the UI
 * is determined by the time Ruby code gets run. If ruby is the main program,
 * we need to load the UI frontend if we need one.
 *
 * Assign "ncurses" or "qt" before UI calls.
 *
 *    #! /usr/bin/env ruby
 *    require "yast"
 *    include Yast
 *    include Yast::UIShortcuts
 *
 *    if Yast.ui_component == ""
 *      Yast.ui_component = ARGV[0] || "ncurses"
 *    end
 *
 *    Builtins.y2milestone("UI component: %1", Yast.ui_component)
 *    Yast.import "UI"
 *
 *    UI.OpenDialog(PushButton("This is a button"))
 *    UI.UserInput
 *    UI.CloseDialog
 */
static VALUE ui_set_component(VALUE self, VALUE name)
{
  YUIComponent *c = YUIComponent::uiComponent();
  if (c)
  {
    YUIComponent::setUseDummyUI(false);

    string s = StringValuePtr(name);
    c->setRequestedUIName(s);
  }

  return Qnil;
}

static void init_ui()
{
  // init_ui is needed only for running tests. YaST itself setup UI in y2base
  // respective its ruby version when this env variable is specified.
  // So skip initialization here to avoid conflicts.
  if (getenv("YAST_IS_RUNNING") != NULL)
    return;

  const char *ui_name = "UI";

  Y2Component *c = YUIComponent::uiComponent();
  if (c == 0)
  {
    y2debug ("UI component not created yet, creating %s", ui_name);

    c = Y2ComponentBroker::createServer(ui_name); // just dummy ui if none is defined
    if (c == 0)
    {
      y2error("can't create UI component");
      return;
    }

    c->setServerOptions(0, NULL);
  }
  else
  {
    y2debug("UI component already present: %s", c->name ().c_str ());
  }
}

static VALUE ui_create(VALUE self, VALUE name, VALUE args)
{
  Y2ComponentBroker::getNamespaceComponent("UI");

  string name_s = StringValuePtr(name);
  y2debug("creating UI %s", name_s.c_str());
  Y2Component *server = Y2ComponentBroker::createServer(name_s.c_str());
  int argc = RARRAY_LENINT(args);
  char **argv = new char *[argc+1];
  for (long i = 0; i < argc; ++i)
  {
    VALUE a = rb_ary_entry(args, i);
    argv[i] = strdup(StringValuePtr(a));
  }
  argv[argc] = NULL;

  server->setServerOptions(argc, argv);

  return Qnil;
}

static VALUE ui_finalizer()
{
  YUIComponent *c = YUIComponent::uiComponent();
  if (c)
  {
    // Shut down the component.
    c->result(YCPVoid());
  }
  return Qnil;
}

} //extern C

extern "C"
{
  /*
   * Ruby module initializer
   *
   * "require 'ycpx'" will call Init_ycpx()
   */

  void
  Init_yastx()
  {
    YCPPathSearch::initialize();
    init_ui();

    /*
     * module YCP
     */
    rb_mYast = rb_define_module("Yast");
    rb_define_singleton_method( rb_mYast, "import_pure", RUBY_METHOD_FUNC(ycp_module_import), 1);
    rb_define_singleton_method( rb_mYast, "find_include_file", RUBY_METHOD_FUNC(ycp_find_include_file), 1);

    rb_define_singleton_method( rb_mYast, "call_yast_function", RUBY_METHOD_FUNC(ycp_module_call_ycp_function), -1);

    rb_define_singleton_method( rb_mYast, "symbols", RUBY_METHOD_FUNC(ycp_module_symbols), 1);
    rb_define_singleton_method( rb_mYast, "y2paths", RUBY_METHOD_FUNC(y2dir_paths), 0);

    rb_define_method( rb_mYast, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);
    rb_define_singleton_method( rb_mYast, "y2_logger", RUBY_METHOD_FUNC(yast_y2_logger), -1);

    // UI initialization
    rb_define_singleton_method( rb_mYast, "ui_create",     RUBY_METHOD_FUNC(ui_create), 2);
    rb_define_singleton_method( rb_mYast, "ui_component",  RUBY_METHOD_FUNC(ui_get_component), 0);
    rb_define_singleton_method( rb_mYast, "ui_component=", RUBY_METHOD_FUNC(ui_set_component), 1);
    rb_define_singleton_method( rb_mYast, "ui_finalizer",  RUBY_METHOD_FUNC(ui_finalizer), 0);

    // Y2 references
    rb_cYReference = rb_define_class_under(rb_mYast, "YReference", rb_cObject);
    rb_define_method(rb_cYReference, "call", RUBY_METHOD_FUNC(ref_call), -1);

    // Y2 code
    rb_cYCode = rb_define_class_under(rb_mYast, "YCode", rb_cObject);
    rb_define_method(rb_cYCode, "call", RUBY_METHOD_FUNC(code_call), -1);

    //Byteblock
    rb_cByteblock = rb_define_class_under(rb_mYast, "Byteblock", rb_cObject);
    rb_define_method(rb_cByteblock, "to_s", RUBY_METHOD_FUNC(byteblock_to_s), 0);
  }
}
