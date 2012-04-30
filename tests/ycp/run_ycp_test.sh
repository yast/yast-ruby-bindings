#!/bin/sh
# $1 is the test case
if [ -z "$1" ]; then
  echo "Missing file to run" >&2
  echo "Usage: run_ycp_test.sh <test file>" >&2
  exit 1
fi
DIR=${1%/*}
# RPM_BUILD_ROOT will hold the YCP Ruby plugin at rpm build time
if [ -d $RPM_BUILD_ROOT/usr/lib64 ]; then #we are on 64bit
  export Y2DIR=$RPM_BUILD_ROOT/usr/lib64/YaST2
else
  export Y2DIR=$RPM_BUILD_ROOT/usr/lib/YaST2
fi
# DEBUG=valgrind
# DEBUG="strace -s1000 -o log -e trace=file"
: ${PREFIX=/usr}
$DEBUG $PREFIX/lib/YaST2/bin/y2base -l - -M $DIR $1 UI
