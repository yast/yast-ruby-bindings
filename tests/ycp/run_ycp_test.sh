#!/bin/sh
# $1 is the test case
DIR=${1%/*}
# RPM_BUILD_ROOT will hold the YCP Ruby plugin at rpm build time
export Y2DIR=$RPM_BUILD_ROOT/usr/lib/YaST2
# DEBUG=valgrind
# DEBUG="strace -s1000 -o log -e trace=file"
: ${PREFIX=/usr}
$DEBUG $PREFIX/lib/YaST2/bin/y2base -l - -M $DIR $1 UI
