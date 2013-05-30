# -----------------------------------------------------------------------\
# |                                                                      |
# |                      __   __    ____ _____ ____                      |
# |                      \ \ / /_ _/ ___|_   _|___ \                     |
# |                       \ V / _` \___ \ | |   __) |                    |
# |                        | | (_| |___) || |  / __/                     |
# |                        |_|\__,_|____/ |_| |_____|                    |
# |                                                                      |
# |                                                                      |
# | ruby language support                              (C) Novell Inc.   |
# \----------------------------------------------------------------------/
#
# Author: Duncan Mac-Vicar <dmacvicar@suse.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version
# 2 of the License, or (at your option) any later version.
#

# Load the native part (.so)
require 'ycpx'

#load global YCP module
require 'ycp/ycp'

# load inside moduls
require "ycp/arg_ref"
require "ycp/break"
require "ycp/builtins"
require "ycp/client"
require "ycp/convert"
require "ycp/exportable"
require "ycp/external"
require "ycp/fun_ref"
require "ycp/i18n"
require "ycp/logger"
require "ycp/module"
require "ycp/ops"
require "ycp/path"
require "ycp/scr"
require "ycp/term"
require "ycp/ui"
require "ycp/wfm"
