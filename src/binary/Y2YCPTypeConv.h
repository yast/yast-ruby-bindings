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

#ifndef Y2YCPTYPECONV_H
#define Y2YCPTYPECONV_H

#include <ycp/YCPValue.h>
#include <ruby.h>

/**
 * Converts a YCPValue into a Ruby Value
 * Supports neested lists and maps using recursion.
 */
extern "C" VALUE
ycpvalue_2_rbvalue( YCPValue ycpval );

#endif
