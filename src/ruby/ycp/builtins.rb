require "ycp/path"
require "ycp/helper"

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
      when Array then return object + params
      when Hash then  return object.merge(Hash[*params])
        #TODO when YCP::Term:
      when YCP::Path then return object + params.first
      else
        raise "Invalid object for add builtin"
      end
    end

    # - Changes a list. Deprecated, use LIST[size(LIST)] = value.
    # - Change element pair in a map. Deprecated, use MAP[KEY] = VALUE.
    def self.change
      raise "Builtin change() is not implemented yet"
    end

    # - Filters a List
    # - Filter a Map
    def self.filter
      raise "Builtin filter() is not implemented yet"
    end

    # find() YCP built-in
    # - Returns position of a substring
    # - Searches for the first occurence of a certain element in a list
    def self.find object, what
      return nil if object.nil? || what.nil?

      case object
      when String then return object.index what
      when Array then raise "find(<Array>) is not implemented"
      else
        raise "Invalid object for find() builtin"
      end
    end

    # - Process the content of a map
    # - Processes the content of a list
    def self.foreach
      raise "Builtin foreach() is not implemented yet"
    end

    # - Returns whether the map m is empty.
    # - Returns whether the string s is empty.
    # - Returns whether the list l is empty.
    def self.isempty
      raise "Builtin isempty() is not implemented yet"
    end

    # - Maps an operation onto all elements key/value and create a list
    # - Maps an operation onto all elements of a list and thus creates a new list.
    def self.maplist
      raise "Builtin maplist() is not implemented yet"
    end

    # - Removes element from a list
    # - Remove key/value pair from a map
    # - Remove item from term
    def self.remove
      raise "Builtin remove() is not implemented yet"
    end

    # - Selects a list element (deprecated, use LIST[INDEX]:DEFAULT)
    # - Select item from term
    def self.select
      raise "Builtin select() is not implemented yet"
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
      when String, Array, Hash, YCP::Term then return object.size
      # TODO: byteblock, path
      else
        raise "Invalid object for size() builtin"
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
      def self.abs
        raise "Builtin abs() is not implemented yet"
      end

    	# round upwards to integer
      def self.ceil
        raise "Builtin ceil() is not implemented yet"
      end

    	# round downwards to integer
      def self.floor
        raise "Builtin floor() is not implemented yet"
      end

    	# power function
      def self.pow
        raise "Builtin pow() is not implemented yet"
      end

    	# Converts a floating point number to a localized string
      def self.tolstring
        raise "Builtin tolstring() is not implemented yet"
      end

    	# round to integer, towards zero
      def self.trunc
        raise "Builtin trunc() is not implemented yet"
      end
    end
    
    # Converts a value to a floating point number.
    def self.tofloat
      raise "Builtin tofloat() is not implemented yet"
    end

    # Converts a floating point number to a string
    def self.tostring
      raise "Builtin tostring() is not implemented yet"
    end

    ###########################################################
    # YCP Integer Builtins
    ###########################################################

    # Converts a value to an integer.
    def self.tointeger
      raise "Builtin tointeger() is not implemented yet"
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
    def self.flatten
      raise "Builtin flatten() is not implemented yet"
    end
    
    module List
      # Reduces a list to a single value.
      def self.reduce
        raise "Builtin list::reduce() is not implemented yet"
      end

      # Reduces a list to a single value.
      def self.reduce
        raise "Builtin list::reduce() is not implemented yet"
      end

      # Creates new list with swaped elemetns at offset i1 and i2.
      def self.swap
        raise "Builtin list::swap() is not implemented yet"
      end
    end

    # Maps an operation onto all elements of a list and thus creates a map.
    def self.listmap
      raise "Builtin listmap() is not implemented yet"
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
    def self.prepend
      raise "Builtin prepend() is not implemented yet"
    end

    # setcontains() YCP built-in
    # Checks if a sorted list contains an element
    def self.setcontains list, value
      # simply call contains(), setcontains() is just optimized contains() call
      contains list, value
    end

    # sort() YCP built-in
    # Sorts a List according to the YCP builtin predicate
    # TODO FIXME: Sort list using an expression
    def self.sort array
      return nil if array.nil?

      array.sort
    end

    # splitstring() YCP built-in
    # Split a string by delimiter
    def self.splitstring string, sep
      return nil if string.nil? || sep.nil?
      return [] if sep.empty?

      # the big negative value forces keeping empty values in the list
      string.split /[#{Regexp.escape sep}]/, -1 * 2**20
    end

    # Extracts a sublist
    def self.sublist
      raise "Builtin sublist() is not implemented yet"
    end

    # Extracts a sublist
    def self.sublist
      raise "Builtin sublist() is not implemented yet"
    end

    # Converts a value to a list (deprecated, use (list)VAR).
    def self.tolist
      raise "Builtin tolist() is not implemented yet"
    end

    # toset() YCP built-in
    # Sorts list and removes duplicates
    def self.toset array
      return nil if array.nil?
      array.uniq.sort
    end

    # Unions of lists
    def self.union
      raise "Builtin union() is not implemented yet"
    end

    ###########################################################
    # Map Builtins
    ###########################################################

    # Check if map has a certain key
    def self.haskey
      raise "Builtin haskey() is not implemented yet"
    end

    # Select a map element (deprecated, use MAP[KEY]:DEFAULT)
    def self.lookup
      raise "Builtin lookup() is not implemented yet"
    end

    # Maps an operation onto all key/value pairs of a map
    def self.mapmap
      raise "Builtin mapmap() is not implemented yet"
    end

    # Converts a value to a map.
    def self.tomap
      raise "Builtin tomap() is not implemented yet"
    end

    # Union of 2 maps
    def self.union
      raise "Builtin union() is not implemented yet"
    end

    ###########################################################
    # Miscellaneous YCP Builtins
    ###########################################################

    # Evaluate a YCP value.
    def self.eval
      raise "Builtin eval() is not implemented yet"
    end

    # Change or add an environment variable
    def self.getenv
      raise "Builtin getenv() is not implemented yet"
    end

    # Checks whether a value is of a certain type
    def self.is
      raise "Builtin is() is not implemented yet"
    end

    # Random number generator.
    def self.random
      raise "Builtin random() is not implemented yet"
    end

    # Change or add an environment variable
    def self.setenv env, value, overwrite = true
      raise "Builtin setenv() is not implemented yet"
    end

    # Format a String
    def self.sformat
      raise "Builtin sformat() is not implemented yet"
    end

    # Sleeps a number of milliseconds.
    def self.sleep
      raise "Builtin sleep() is not implemented yet"
    end

    # Initialize random number generator
    def self.srandom
      raise "Builtin srandom() is not implemented yet"
    end

    # Initialize random number generator.
    def self.srandom
      raise "Builtin srandom() is not implemented yet"
    end

    # time() YCP built-in
    # Return the number of seconds since 1.1.1970.
    def self.time
      Time.now.to_i
    end

    # Log a message to the y2log.
    def self.y2debug
      raise "Builtin y2debug() is not implemented yet"
    end

    # Log an error to the y2log.
    def self.y2error
      raise "Builtin y2error() is not implemented yet"
    end

    # Log an internal message to the y2log.
    def self.y2internal
      raise "Builtin y2internal() is not implemented yet"
    end

    # Log a milestone to the y2log.
    def self.y2milestone
      raise "Builtin y2milestone() is not implemented yet"
    end

    # Log a security message to the y2log.
    def self.y2security
      raise "Builtin y2security() is not implemented yet"
    end

    # Log an user-level system message to the y2changes
    def self.y2useritem
      raise "Builtin y2useritem() is not implemented yet"
    end

    # Log an user-level addional message to the y2changes
    def self.y2usernote
      raise "Builtin y2usernote() is not implemented yet"
    end

    # Log a warning to the y2log.
    def self.y2warning
      raise "Builtin y2warning() is not implemented yet"
    end

    ###########################################################
    # YCP Path Builtins
    ###########################################################

    # Converts a value to a path.
    def self.topath
      raise "Builtin topath() is not implemented yet"
    end

    ###########################################################
    # YCP String Builtins
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
    def self.deletechars
      raise "Builtin deletechars() is not implemented yet"
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

    # Filters characters out of a String
    def self.filterchars
      raise "Builtin filterchars() is not implemented yet"
    end

    # Searches string for the first non matching chars
    def self.findfirstnotof
      raise "Builtin findfirstnotof() is not implemented yet"
    end

    # Finds position of the first matching characters in string
    def self.findfirstof
      raise "Builtin findfirstof() is not implemented yet"
    end

    # Searches the last element of string that doesn't match
    def self.findlastnotof
      raise "Builtin findlastnotof() is not implemented yet"
    end

    # Searches string for the last match
    def self.findlastof
      raise "Builtin findlastof() is not implemented yet"
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
          ret.gsub! "\\#{i + 1}", str
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

    # Returns position of a substring
    def self.search
      raise "Builtin search() is not implemented yet"
    end

    # Returns part of a string
    def self.substring
      raise "Builtin substring() is not implemented yet"
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
    def self.tohexstring
      raise "Builtin tohexstring() is not implemented yet"
    end

    # Converts an integer to a hexadecimal string.
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
    def self.tostring
      raise "Builtin tostring() is not implemented yet"
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
    def self.argsof
      raise "Builtin argsof() is not implemented yet"
    end

    # Returns the symbol of the term TERM.
    def self.symbolof
      raise "Builtin symbolof() is not implemented yet"
    end

    # Converts a value to a term.
    def self.toterm
      raise "Builtin toterm() is not implemented yet"
    end

    # Constructs a term from a symbol and a list.
    def self.toterm
      raise "Builtin toterm() is not implemented yet"
    end

  end
end
