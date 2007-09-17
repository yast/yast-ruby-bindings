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
require 'yastx'

module YaST

  class Builder
    # blank slate
    instance_methods.each { |m| undef_method m unless (m =~ /^__|instance_eval$/)}
    
    def initialize(&block)
        @buffer = Array.new
        @term = nil
        @term = instance_eval(&block)
    end
    
    def method_missing(name, *args, &block )
  #    puts "hi #{name.to_s} | #{args}"
      term = nil
      elements = block ? nil : args
      @__to_s = nil # invalidate to_s cache
      term = YaST::Term.new(name.to_s)
      if not elements.nil?
  #puts "here"
        @buffer << name << "("
        elements.each do | e |
          @buffer << e.to_s
          term.add(e)
        end
        @buffer << ") "
        return term
      else
  #     puts "there"
        @buffer << name << "(" 
        r = instance_eval(&block)
        puts term.class
        term.add(r) if not r.nil?
        @buffer << ") "
      end
      return term
    end
    
    def to_s
      return @term.to_s
    end
  end

end # module YaST