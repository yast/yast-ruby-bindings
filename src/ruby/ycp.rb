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

# load inside moduls
require "ycp/break"
require "ycp/builtins"
require "ycp/convert"
require "ycp/exportable"
require "ycp/logger"
require "ycp/ops"
require "ycp/path"
require "ycp/scr"
require "ycp/term"
require "ycp/wfm"

module YCP
  def self.import(mname)
    import_pure(mname)
    return if const_defined? mname
    m = Module.new
    symbols(mname).each do |sname,stype|
      next if sname.empty?
      if (stype == :function)
        m.module_eval <<-"END"
          def self.#{sname}(*args)
            return YCP::call_ycp_function("#{mname}", :#{sname}, *args)
          end
        END
      end
      if stype == :variable
        m.module_eval <<-"END"
          def self.#{sname}
            return YCP::call_ycp_function("#{mname}", :#{sname})
          end
          def self.#{sname}= (value)
            return YCP::call_ycp_function("#{mname}", :#{sname}, value)
          end
        END
      end
    end
    self.const_set(mname, m)
  end
end

#--------------------------------------
#
# YCP::Ui
#

module YCP
  module Ui

  # Define symbols for the UI
  ui_terms = [ :BarGraph, :Bottom, :CheckBox, :ColoredLabel, :ComboBox, :Date,
    :DownloadProgress, :DumbTab, :DummySpecialWidget, :Empty, :Frame, :HBox, :HBoxvHCenter,
    :HMultiProgressMeter, :HSpacing, :HSquash, :HStretch, :HVCenter, :HVSquash,
    :HVStretch, :HWeight, :Heading, :IconButton, :Image, :IntField, :Label, :Left, :LogView,
    :MarginBox, :MenuButton, :MinHeight, :MinSize, :MinWidth, :MultiLineEdit,
    :MultiSelectionBox, :PackageSelector, :PatternSelector, :PartitionSplitter,
    :Password, :PkgSpecial, :ProgressBar, :PushButton, :RadioButton,
    :RadioButtonGroup, :ReplacePoint, :RichText, :Right, :SelectionBox, :Slider, :Table,
    :TextEntry, :Time, :Top, :Tree, :VBox, :VCenter, :VMultiProgressMeter, :VSpacing,
    :VSquash, :VStretch, :VWeight, :Wizard,
    :id, :opt ]

   # for each symbol define a util function that will create a term
    ui_terms.each do | term_name |
      define_method(term_name) do | *args |
        t = YaST::Term.new(term_name.to_s)
        args.each do |arg|
          t.add(arg)
        end
        return t
      end
      alias_method term_name.to_s.downcase, term_name
    end

  end # end Ui module
end
