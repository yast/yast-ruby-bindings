require "ycp/path"
require "ycp/helper"
require "ycp/break"

module YCP
  module Builtins

    ###########################################################
    # Overloaded Builtins
    ###########################################################

    # - Add a key/value pair to a map - add(<map>, <key>, <value)
    # - Create a new list with a new element - add(<list>, <value>)
    # - Add value to term - add(<term>, <value>)
    # - Add a path element to existing path - add(<path>, <value>)
    # Method that simulates behavior of add in ycp builtin.
    # Most notably difference is that it always create new object
    # For new code it is recommended to use directly methods on objects
    def self.add object, *params
      case object
      when ::Array then return object + params
      when ::Hash then  return object.merge(::Hash[*params])
      when YCP::Path then return object + params.first
      when YCP::Term then
        res = object.dup
        res.params << params.first
        return res
      when NilClass then return nil
      else
        raise "Invalid object for add builtin"
      end
    end

    # - Changes a list. Deprecated, use LIST[size(LIST)] = value. - change(<list>, <val>)
    # - Change element pair in a map. Deprecated, use MAP[KEY] = VALUE. - change(<map>, <key>, <value>)
    # it's obsoleted, behaves like add() builtin now
    def self.change object, *params
      add object, *params
    end

    # - Filters a List
    # - Filter a Map
    def self.filter object, &block
      #TODO investigate break and continue with filter as traverse workflow is different for ruby
      if object.is_a?(::Array) || object.is_a?(::Hash)
        object.select &block
      else
        return nil
      end
    end

    # find() YCP built-in
    # - Returns position of a substring (-1 if not found)
    # - Searches for the first occurence of a certain element in a list
    def self.find object, what=nil, &block
      return nil if object.nil? || (what.nil? && block.nil?)

      case object
      when ::String
        ret = object.index what
        return ret.nil? ? -1 : ret
      when ::Array
        object.find &block
      else
        raise "Invalid object for find() builtin"
      end
    end

    # - Process the content of a map
    # - Processes the content of a list
    def self.foreach object, &block
      res = nil
      if object.is_a? ::Array
        begin
          object.each do |i|
            res = block.call(i)
          end
        rescue YCP::Break
          res = nil
        end
      elsif object.is_a? ::Hash
        begin
          object.each_pair do |k,v|
            res = block.call(k,v)
          end
        rescue YCP::Break
          res = nil
        end
      else
        YCP.y2warning ("foreach builtin called on wrong type #{object.class}")
      end
      return res
    end

    # - Returns whether the map m is empty.
    # - Returns whether the string s is empty.
    # - Returns whether the list l is empty.
    def self.isempty object
      return nil if object.nil?
      object.empty?
    end

    # - Maps an operation onto all elements key/value and create a list
    # - Maps an operation onto all elements of a list and thus creates a new list.
    def self.maplist object, &block
      case object
      when ::Array
        res = []
        begin
          object.each do |i|
            res << block.call(i)
          end
        rescue YCP::Break
          #break skips out of each loop, but allow to keep previous results
        end
        return res
      when ::Hash
        res = []
        begin
          object.each do |i|
            res << block.call(i)
          end
        rescue YCP::Break
          #break skips out of each loop, but allow to keep previous results
        end
        return res
      else
        YCP.y2warning ("Called builtin maplist on wrong type #{object.class}")
        return nil
      end
    end

    # - Removes element from a list
    # - Remove key/value pair from a map
    # - Remove item from term
    def self.remove object, element
      return nil if object.nil?

      res = object.dup
      return res if element.nil?
      case object
      when ::Array
        return res if element < 0
        res.delete_at element
      when ::Hash
        res.delete element
      when YCP::Term
        return res if element < 1
        res.params.delete_at element-1
      else
        raise "Invalid type passed to remove #{object.class}"
      end

      return res
    end

    # - Selects a list element (deprecated, use LIST[INDEX]:DEFAULT)
    # - Select item from term
    def self.select object, element, default
      YCP::Ops.index(object, [element], default)
    end

    # size() YCP built-in
    # - Size of a map
    # - Returns the number of path elements
    # - Returns size of list
    # - Returns a size of a byteblock in bytes.
    # - Returns the number of arguments of the term TERM.
    # - Returns the number of characters of the string s
    def self.size object
      return nil if object.nil?

      case object
      when ::String, ::Array, ::Hash, YCP::Term, YCP::Path
        return object.size
      # TODO: byteblock
      else
        raise "Invalid object for size() builtin"
      end
    end

    # Initialize random number generator - srandom(<int>)
    # Get the current random number generator seed - int srandom()
    def self.srandom param=nil
      if param.nil?
        # be more secure here, original YCP uses Time.now with second precision
        # for seeding which is not secure enough, calling Ruby srand without
        # paramater causes to use time, PID and a sequence number for seeding
        # which is more secure
        srand

        # the original srandom() returns Time.now
        Time.now.to_i
      else
        srand param
        return nil
      end
    end

    # - Unions of lists
    # - Union of 2 maps
    def self.union first, second
      return nil if first.nil? || second.nil?

      case first
      when ::Array
        return (first+second).reduce([]) do |acc,i|
          acc << i unless acc.include? i
          acc
        end
      when ::Hash
        return first.merge(second)
      else
        raise "Wrong type #{first.class} to union builtin"
      end
    end


    ###########################################################
    # YCP Byteblock Builtins
    ###########################################################

    # Converts a value to a byteblock.
    def self.tobyteblock
      raise "Builtin tobyteblock() is not implemented yet"
    end

    ###########################################################
    # YCP Float Builtins
    ###########################################################

    module Float
    	# absolute value
      def self.abs value
        return nil if value.nil?

        return value.abs
      end

    	# round upwards to integer
      def self.ceil value
        return nil if value.nil?

        return value.ceil.to_f
      end

    	# round downwards to integer
      def self.floor value
        return nil if value.nil?

        return value.floor.to_f
      end

    	# power function
      def self.pow base, power
        return nil if base.nil? || power.nil?

        return base ** power
      end

    	# Converts a floating point number to a localized string
      def self.tolstring value, precision
        raise "Builtin float::tolstring() is not implemented yet"
      end

    	# round to integer, towards zero
      def self.trunc value
        return nil if value.nil?

        return value.to_i.to_f
      end
    end

    # Converts a value to a floating point number.
    def self.tofloat value
      return nil if value.nil?

      return value.to_f
    rescue
      return nil
    end

    ###########################################################
    # YCP Integer Builtins
    ###########################################################

    # Converts a value to an integer.
    def self.tointeger object
      return nil if object.nil?

      case object
      # use full qualified ::Float to avoid clash with YCP::Builtins::Float
      when ::String, ::Float, Fixnum, Bignum
        object.to_i
      else
        nil
      end
    end

    ###########################################################
    # YCP List Builtins
    ###########################################################

    # contains() YCP built-in
    # Checks if a list contains an element
    def self.contains list, value
      return nil if list.nil? || value.nil?
      list.include? value
    end

    # Flattens List
    def self.flatten value
      return nil if value.nil?

      return value.reduce([]) do |acc,i|
        return nil if i.nil?
        acc.push *i
      end
    end

    module List
      # Reduces a list to a single value.
      def self.reduce *params, &block
        return nil if params.first.nil?
        list = params.first
        if params.size == 2
          return nil if params[1].nil?
          list = [list] + params[1]
        end
        return list.reduce &block
      end


      # Creates new list with swaped elemetns at offset i1 and i2.
      def self.swap list, offset1, offset2
        return nil if list.nil? || offset1.nil? || offset2.nil?

        return list if offset1 < 0 || offset2 >= list.size || (offset1 > offset2)

        res = []
        if offset1 > 0
          res.concat list[0..offset1-1]
        end
        res.concat list[offset1..offset2].reverse!
        if offset2 < list.size-1
          res.concat list[offset2+1..-1]
        end
        return res
      end
    end

    # Maps an operation onto all elements of a list and thus creates a map.
    def self.listmap list, &block
      return nil if list.nil?

      res = ::Hash.new
      begin
        list.each do |i|
          res.merge! block.call(i)
        end
      rescue YCP::Break
        #break stops adding to hash
      end

      return res
    end

    # Sort A List respecting locale
    def self.lsort
      raise "Builtin lsort() is not implemented yet"
    end

    # merge() YCP built-in
    # Merges two lists into one
    def self.merge a1, a2
      return nil if a1.nil? || a2.nil?
      a1 + a2
    end

    # Prepends a list with a new element
    def self.prepend list, element
      return nil if list.nil?

      return [element].push *list
    end

    # setcontains() YCP built-in
    # Checks if a sorted list contains an element
    def self.setcontains list, value
      # simply call contains(), setcontains() is just optimized contains() call
      contains list, value
    end

    # sort() YCP built-in
    # Sorts a List according to the YCP builtin predicate
    def self.sort array, &block
      return nil if array.nil?

      if block_given?
        array.sort { |x,y| block.call(x,y) ? 1 : -1 }
      else  
        array.sort {|x,y| YCP::Ops.comparable_object(x) <=> y }
      end
    end

    # splitstring() YCP built-in
    # Split a string by delimiter
    def self.splitstring string, sep
      return nil if string.nil? || sep.nil?
      return [] if sep.empty?

      # the big negative value forces keeping empty values in the list
      string.split /[#{Regexp.escape sep}]/, -1 * 2**20
    end

    # we must mark somehow default value for length
    DEF_LENGHT = "default"
    # Extracts a sublist
    # - sublist(<list>, <offset>)
    # - sublist(<list>, <offset>, <length>)
    def self.sublist list, offset, length=DEF_LENGHT
      return nil if list.nil? || offset.nil? || length.nil?

      length = list.size - offset if length==DEF_LENGHT
      return nil if offset < 0 || offset >= list.size
      return nil if length < 0 || offset+length > list.size

      return list.dup[offset..offset+length-1]
    end

    # Converts a value to a list (deprecated, use (list)VAR).
    def self.tolist object
      return object.is_a?(::Array) ? object : nil
    end

    # toset() YCP built-in
    # Sorts list and removes duplicates
    def self.toset array
      return nil if array.nil?
      array.uniq.sort { |x,y| YCP::Ops.comparable_object(x) <=> y }
    end

    ###########################################################
    # Map Builtins
    ###########################################################

    # Check if map has a certain key
    def self.haskey map, key
      return nil if map.nil? || key.nil?
      map.has_key? key
    end

    # Select a map element (deprecated, use MAP[KEY]:DEFAULT)
    def self.lookup map, key, default
      map.has_key?(key) ? map[key] : default
    end

    # Maps an operation onto all key/value pairs of a map
    def self.mapmap map, &block
      return nil if map.nil?

      res = ::Hash.new
      begin
        map.each_pair do |k,v|
          res.merge! block.call(k,v)
        end
      rescue YCP::Break
        #break stops adding to hash
      end

      return res
    end

    # Converts a value to a map.
    def self.tomap object
      return object.is_a?(::Hash) ? object : nil
    end

    ###########################################################
    # Miscellaneous YCP Builtins
    ###########################################################

    # Evaluate a YCP value.
    def self.eval object
      if object.respond_to? :call
        return object.call
      else
        return object
      end
    end

    # Change or add an environment variable
    def self.getenv value
      return ENV[value]
    end

    # Random number generator.
    def self.random max
      return nil if max.nil?

      return max < 0 ? -rand(max) : rand(max)
    end

    # Change or add an environment variable
    def self.setenv env, value, overwrite = true
      return true if ENV.include?(env)

      ENV[env] = value
      return true
    end

    # Format a ::String
    def self.sformat format, *args
      if format.nil? || !format.is_a?(::String)
        return nil
      end

      return format if args.empty?

      return format.gsub(/%./) do |match|
        case match
        when "%%"
          "%"
        when /%([1-9])/
          pos = $1.to_i - 1
          if (pos < args.size)
            args[pos]
          else
            YCP.y2warning "Illegal argument number #{match}. Maximum is %#{args.size-1}."
            ""
          end
        else
          YCP.y2warning "Illegal argument number #{match}."
          ""
        end
      end
    end

    # Sleeps a number of milliseconds.
    def self.sleep milisecs
      # ruby sleep() accepts seconds (float)
      sleep milisecs / 1000.0
    end

    # time() YCP built-in
    # Return the number of seconds since 1.1.1970.
    def self.time
      Time.now.to_i
    end

    # Log a message to the y2log.
    def self.y2debug *args
      shift_frame_number args
      YCP.y2debug *args
    end

    # Log an error to the y2log.
    def self.y2error *args
      shift_frame_number args
      YCP.y2error *args
    end

    # Log an internal message to the y2log.
    def self.y2internal *args
      shift_frame_number args
      YCP.y2internal *args
    end

    # Log a milestone to the y2log.
    def self.y2milestone*args
      shift_frame_number args
      YCP.y2milestone *args
    end

    # Log a security message to the y2log.
    def self.y2security *args
      shift_frame_number args
      YCP.y2security *args
    end

    # Log a warning to the y2log.
    def self.y2warning *args
      shift_frame_number args
      YCP.y2warning *args
    end

    def self.shift_frame_number args
      if args.first.is_a? Fixnum
        args[0] = args.first + 1
      else 
        args.unshift 1
      end
    end

    # Log an user-level system message to the y2changes
    def self.y2useritem *args
      # TODO implement it
      return nil
    end

    # Log an user-level addional message to the y2changes
    def self.y2usernote *args
      # TODO implement it
      return nil
    end

    ###########################################################
    # YCP Path Builtins
    ###########################################################

    # Converts a value to a path.
    def self.topath object
      case object
      when YCP::Path
        return object
      when ::String
        object = "."+object unless object.start_with?(".")
        return YCP::Path.new object
      else
        return nil
      end
    end

    ###########################################################
    # YCP ::String Builtins
    ###########################################################

    # Encrypts a string
    def self.crypt
      raise "Builtin crypt() is not implemented yet"
    end

    # Encrypts a string using bigcrypt
    def self.cryptbigcrypt
      raise "Builtin cryptbigcrypt() is not implemented yet"
    end

    # Encrypts a string with blowfish
    def self.cryptblowfish
      raise "Builtin cryptblowfish() is not implemented yet"
    end

    # Encrypts a string using md5
    def self.cryptmd5
      raise "Builtin cryptmd5() is not implemented yet"
    end

    # Removes all characters from a string
    def self.deletechars string, chars
      return nil if !string || !chars

      # handle special characters that is handled by delete but not by ycp
      chars = "-" + chars.delete("-") if chars.include? "-"
      chars = chars.delete("^") + "^" if chars.include? "^"

      string.delete chars
    end

    # Translates the text using the given text domain
    def self.dgettext
      raise "Builtin dgettext() is not implemented yet"
    end

    # Translates the text using a locale-aware plural form handling
    def self.dngettext
      raise "Builtin dngettext() is not implemented yet"
    end

    # Translates the text using the given text domain and path
    def self.dpgettext
      raise "Builtin dpgettext() is not implemented yet"
    end

    # Filters characters out of a ::String
    def self.filterchars
      raise "Builtin filterchars() is not implemented yet"
    end

    # Searches string for the first non matching chars
    def self.findfirstnotof string, chars
      return nil if string.nil? || chars.nil?

      return string.index /^[#{Regexp.escape chars}]/
    end

    # Finds position of the first matching characters in string
    def self.findfirstof string, chars
      return nil if string.nil? || chars.nil?

      return string.index /[#{Regexp.escape chars}]/
    end

    # Searches the last element of string that doesn't match
    def self.findlastnotof string, chars
      return nil if string.nil? || chars.nil?

      return string.rindex /^[#{Regexp.escape chars}]/
    end

    # Searches string for the last match
    def self.findlastof string, chars
      return nil if string.nil? || chars.nil?

      return string.rindex /[#{Regexp.escape chars}]/
    end

    # issubstring() YCP built-in
    # searches for a specific string within another string
    def self.issubstring string, substring
      return nil if string.nil? || substring.nil?
      string.include? substring
    end

    # Extracts a substring in UTF-8 encoded string
    def self.lsubstring
      raise "Builtin lsubstring() is not implemented yet"
    end

    # mergestring() YCP built-in
    # Joins list elements with a string
    def self.mergestring string, sep
      return nil if string.nil? || sep.nil?

      string.join sep
    end

    # regexpmatch() YCP built-in
    # Searches a string for a POSIX Extended Regular Expression match.
    def self.regexpmatch string, regexp
      return nil if string.nil? || regexp.nil?

      # TODO FIXME: handle invalid regexps
      ruby_regexp = YCP::Helper.ruby_regexp regexp
      !string.match(ruby_regexp).nil?
    end

    # Returns a pair with position and length of the first match.
    def self.regexppos
      raise "Builtin regexppos() is not implemented yet"
    end

    # regexpsub() YCP built-in
    # Regex Substitution
    def self.regexpsub string, regexp, output
      return nil if string.nil? || regexp.nil? || output.nil?

      ruby_regexp = YCP::Helper.ruby_regexp regexp
      # TODO FIXME: handle invalid regexps
      if match = string.match(ruby_regexp)

        # replace the \num places
        ret = output.dup
        match.captures.each_with_index do |str, i|
          ret.gsub! "\\#{i + 1}", (str||"")
        end

        return ret
      end

      nil
    end

    # regexptokenize() YCP built-in
    # Regex tokenize
    def self.regexptokenize string, regexp
      return nil if string.nil? || regexp.nil?

      begin
        ruby_regexp = YCP::Helper.ruby_regexp regexp
        if match = string.match(ruby_regexp)
          return match.captures
        end
      rescue RegexpError
        # handle invalid regexps
        return nil
      end

      []
    end

    # Returns position of a substring (nil if not found)
    def self.search string, substring
      return nil if string.nil? || substring.nil?
      string.index substring
    end

    # substring() YCP built-in
    # Extracts a substring
    # little bit complicated because YCP returns different values
    # in corner cases (nil or negative parameters, out of range...)
    def self.substring string, offset, length = -1
      return nil if string.nil? || offset.nil? || length.nil?
      return "" if offset < 0 || offset >= string.size

      length = string.size - offset if length < 0

      string[offset, length]
    end

    # Returns time string
    def self.timestring
      raise "Builtin timestring() is not implemented yet"
    end

    # Returns characters below 0x7F included in STRING
    def self.toascii
      raise "Builtin toascii() is not implemented yet"
    end

    # Converts an integer to a hexadecimal string.
    # - tohexstring(<int>)
    # - tohexstring(<int>, <int>width)
    def self.tohexstring
      raise "Builtin tohexstring() is not implemented yet"
    end

    # tolower() YCP built-in
    # Makes a string lowercase
    def self.tolower string
      return nil if string.nil?
      string.downcase
    end

    # Converts a value to a string.
    def self.tostring val
      return "<NULL>" if val.nil?
      return "`#{val}" if val.is_a? ::Symbol

      val.to_s
    end

    # toupper() YCP built-in
    # Makes a string uppercase
    def self.toupper string
      return nil if string.nil?
      string.upcase
    end

    ###########################################################
    # YCP Term Builtins
    ###########################################################

    # Returns the arguments of a term.
    def self.argsof term
      return nil if term.nil?

      return term.params
    end

    # Returns the symbol of the term TERM.
    def self.symbolof
      return nil if term.nil?

      return term.value
    end

    # Converts a value to a term.
    def self.toterm symbol, list=DEF_LENGHT
      return nil if symbol.nil? || list.nil?

      case symbol
      when ::String
        return YCP::Term.new(symbol.to_sym)
      when ::Symbol
        if list==DEF_LENGHT
          return YCP::Term.new(symbol)
        else
          return YCP::Term.new(symbol,*list)
        end
      when YCP::Term
        return symbol
      end
    end

  end
end
