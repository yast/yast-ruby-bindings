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

ENV['LD_LIBRARY_PATH'] = "/usr/lib/YaST2/plugin"

# Load the native part (.so)
require 'yuix'
