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

#include <ruby.h>
#include <y2/Y2Namespace.h>
#include <y2/Y2Function.h>
#include <ycp/YStatement.h>

/**
 * YaST interface to a Ruby module
 */
class YRubyNamespace : public Y2Namespace
{
private:
    string m_name;		//! this namespace's name, eg. XML::Writer
    string ruby_module_name;
    VALUE getRubyModule(); //sets ruby_module name as sideeffect, so we know what is real name in ruby
    void constructSymbolTable(VALUE module);
    int addMethodsNewWay(VALUE module);
    int addMethodsOldWay(VALUE module);
    int addVariables(VALUE module,int offset);
    int addExceptionMethod(VALUE module, int offset);
    void addMethod(const char *name, const string &signature, int offset);

public:
    /**
     * Construct an interface. The module must be already loaded
     * @param name eg "XML::Writer"
     */
    YRubyNamespace (string name);

    virtual ~YRubyNamespace ();

    //! what namespace do we implement
    virtual const string name () const { return m_name; }
    //! used for error reporting
    virtual const string filename () const;

    //! unparse. useful  only for YCP namespaces??
    virtual string toString () const;
    //! called when evaluating the import statement
    // constructor is handled separately
    virtual YCPValue evaluate (bool cse = false);

    virtual Y2Function* createFunctionCall (const string name, constFunctionTypePtr requiredType);
};
