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
require 'yastx'

#load global Yast module
require 'yast/yast'

# load inside moduls
require "yast/arg_ref"
require "yast/break"
require "yast/builtins"
require "yast/client"
require "yast/convert"
require "yast/exportable"
require "yast/external"
require "yast/fun_ref"
require "yast/i18n"
require "yast/logger"
require "yast/y2logger"
require "yast/module"
require "yast/ops"
require "yast/path"
require "yast/scr"
require "yast/term"
require "yast/ui"
require "yast/ui_shortcuts"
require "yast/wfm"

# add yast specific path for ruby libraries, similar to lib directory in rails
# unshift it in reverse order to keep precedence
Yast.y2paths.reverse.each do |p|
  dir_path = File.join(p, "lib")
  if File.exists? dir_path
    $LOAD_PATH.unshift dir_path
  end
end
