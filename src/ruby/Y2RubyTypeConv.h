
#ifndef Y2RUBYTYPECONV_H
#define Y2RUBYTYPECONV_H

#include <ycp/YCPValue.h>
#include "ruby.h"

/**
 * Converts a YCPValue into a Ruby Value
 * Supports neested lists using recursion.
 */
extern "C" VALUE
ycpvalue_2_rbvalue( YCPValue ycpval );

/**
 * Converts a Ruby Value into a YCPValue
 * Supports neested lists using recursion.
 */
YCPValue
rbvalue_2_ycpvalue( VALUE value );

YCPValue
rbvalue_2_ycppath( VALUE value );

#endif

