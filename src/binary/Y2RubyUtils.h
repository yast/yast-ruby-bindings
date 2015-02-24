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

#ifndef Y2RubyUtils_H
#define Y2RubyUtils_H

#include <ruby.h>
#include <string>

/**
 * string to constant, with nested
 * support ("Foo::Bar" strings)
 */
VALUE y2ruby_nested_const_get(const std::string &name);

/**
 * safe variant of rb_require: if an exception happens then log it
 */
bool y2_require(const char *str);

/**
 * Create Ruby String object from a C++ string
 * The resulting string has UTF-8 encoding
 */
VALUE yrb_utf8_str_new(const std::string &str);
VALUE yrb_utf8_str_new(const char *str);

#endif
