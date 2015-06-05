require "set"
require "scanf"

require "yastx"
require "yast/yast"
require "yast/path"
require "yast/break"
require "yast/external"
require "yast/i18n"
require "fast_gettext"
require "yast/builtinx"

module Yast
  class ArgRef; end
  class FunRef; end

  # Contains builtins available in YCP for easier transition. Big part of methods are deprecated.
  #
  # For logging use {Yast::Logger} module instead of deprecated {Builtins.y2milestone},... functions
  #
  # @note All builtins return copy of result
  module Builtins

    # Adds element to copy of element and return such copy.
    # @deprecated Use ruby operators for it.
    def self.add object, *params
      case object
      when ::Array then return Yast.deep_copy(object).concat(Yast.deep_copy(params))
      when ::Hash then  return Yast.deep_copy(object).merge(Yast.deep_copy(::Hash[*params]))
      when Yast::Path then return object + params.first
      when Yast::Term then
        res = Yast.deep_copy(object)
        res.params << Yast.deep_copy(params.first)
        return res
      when ::NilClass then return nil
      else
        raise "Invalid object '#{object.inspect}' for add builtin"
      end
    end

    # - Changes a list. Deprecated, use LIST[size(LIST)] = value. - change(<list>, <val>)
    # - Change element pair in a map. Deprecated, use MAP[KEY] = VALUE. - change(<map>, <key>, <value>)
    # it's obsoleted, behaves like add() builtin now
    # @deprecated use ruby native methods
    def self.change object, *params
      add object, *params
    end

    # - Filters a List
    # - Filter a Map
    # @deprecated use ruby native select method
    def self.filter object, &block
      #TODO investigate break and continue with filter as traverse workflow is different for ruby
      if object.is_a?(::Array) || object.is_a?(::Hash)
        Yast.deep_copy(object).select &block
      else
        return nil
      end
    end

    # find() Yast built-in
    # - Returns position of a substring (-1 if not found)
    # - Searches for the first occurence of a certain element in a list
    # @deprecated use native ruby method find
    def self.find object, what=nil, &block
      return nil if object.nil? || (what.nil? && block.nil?)

      case object
      when ::String
        ret = object.index what
        return ret.nil? ? -1 : Yast.deep_copy(ret)
      when ::Array
        Yast.deep_copy(object.find(&block))
      else
        raise "Invalid object for find() builtin"
      end
    end

    # - Process the content of a map
    # - Processes the content of a list
    # @deprecated use ruby native each method
    def self.foreach object, &block
      res = nil
      object = Yast.deep_copy(object)
      if object.is_a? ::Array
        begin
          object.each do |i|
            res = block.call(i)
          end
        rescue Yast::Break
          res = nil
        end
      elsif object.is_a? ::Hash
        begin
          #sort keys so it behaves same as in Yast
          sort(object.keys).each do |k|
            res = block.call(k,object[k])
          end
        rescue Yast::Break
          res = nil
        end
      else
        Yast.y2warning(1, "foreach builtin called on wrong type #{object.class}")
      end
      return res
    end

    # - Returns whether the map m is empty.
    # - Returns whether the string s is empty.
    # - Returns whether the list l is empty.
    # @deprecated use native `empty?` method
    def self.isempty object
      return nil if object.nil?
      object.empty?
    end

    # - Maps an operation onto all elements key/value and create a list
    # - Maps an operation onto all elements of a list and thus creates a new list.
    # @deprecated use ruby native method {::Enumerable#map}
    def self.maplist object, &block
      case object
      when ::Array
        res = []
        begin
          object.each do |i|
            res << block.call(Yast.deep_copy(i))
          end
        rescue Yast::Break
          #break skips out of each loop, but allow to keep previous results
        end
        return res
      when ::Hash
        res = []
        begin
          sort(object.keys).each do |k|
            res << block.call(Yast.deep_copy(k),Yast.deep_copy(object[k]))
          end
        rescue Yast::Break
          #break skips out of each loop, but allow to keep previous results
        end
        return res
      else
        Yast.y2warning(1, "maplist builtin called on wrong type #{object.class}")
        return nil
      end
    end

    # - Removes element from a list
    # - Remove key/value pair from a map
    # - Remove item from term
    # @deprecated use native ruby method {::Hash#delete},{::Array#delete_at} or {Yast::Term#params} (call delete_at on term params)
    def self.remove object, element
      return nil if object.nil?

      res = Yast.deep_copy(object)
      return res if element.nil?
      case object
      when ::Array
        return res if element < 0

        res.delete_at element
      when ::Hash
        res.delete element
      when Yast::Term
        return res if element < 1

        res.params.delete_at element-1
      else
        raise "Invalid type passed to remove #{object.class}"
      end

      return res
    end

    # - Selects a list element (deprecated, use LIST[INDEX]:DEFAULT)
    # - Select item from term
    # @deprecated use native `[]` operator
    def self.select object, element, default
      Yast::Ops.get(object, [element], default)
    end

    # size() Yast built-in
    # - Size of a map
    # - Returns the number of path elements
    # - Returns size of list
    # - Returns the number of arguments of the term TERM.
    # - Returns the number of characters of the string s
    # @deprecated use builtin {::Array#size},{::Hash#size},{Yast::Term#size},{Yast::Path#size},{::String#size} method
    def self.size object
      return nil if object.nil?

      case object
      when ::String, ::Array, ::Hash, Yast::Term, Yast::Path
        return object.size
      else
        raise "Invalid object for size() builtin"
      end
    end

    # Initialize random number generator - srandom(<int>)
    # Get the current random number generator seed - int srandom()
    # @deprecated use ruby native {::Kernel#srand}
    def self.srandom param=nil
      if param.nil?
        # be more secure here, original Yast uses Time.now with second precision
        # for seeding which is not secure enough, calling Ruby srand without
        # paramater causes to use time, PID and a sequence number for seeding
        # which is more secure
        srand

        # the original srandom() returns Time.now
        ::Time.now.to_i
      else
        srand param
        return nil
      end
    end

    # - Unions of lists
    # - Union of 2 maps
    # @deprecated Use ruby builtins {::Hash#merge} and #{::Array#|}
    def self.union first, second
      return nil if first.nil? || second.nil?

      case first
      when ::Array
        return Yast.deep_copy(first) | Yast.deep_copy(second)
      when ::Hash
        return first.merge(second)
      else
        raise "union builtin called on wrong type #{first.class}"
      end
    end


    ###########################################################
    # Yast Byteblock Builtins
    ###########################################################

    # Converts a value to a byteblock.
    # @note not implmeneted as noone use it as far as we know
    # @deprecated use different byte holder
    def self.tobyteblock
      raise "Builtin tobyteblock() is not implemented yet"
    end

    # builtins enclosed at Float namespace
    # @deprecated all calls are deprecated
    module Float
    	 # absolute value
      # @deprecated Use {::Float#abs} instead
      def self.abs value
        return nil if value.nil?

        return value.abs
      end

    	 # round upwards to integer
      # @deprecated Use {::Float#ceil} instead
      def self.ceil value
        return nil if value.nil?

        return value.ceil.to_f
      end

    	 # round downwards to integer
      # @deprecated Use {::Float#floor} instead
      def self.floor value
        return nil if value.nil?

        return value.floor.to_f
      end

    	 # power function
      # @deprecated Use {::Float#**} instead
      def self.pow base, power
        return nil if base.nil? || power.nil?

        return base ** power
      end

    	 # round to integer, towards zero
      # @deprecated Use {::Float#to_i} instead
      def self.trunc value
        return nil if value.nil?

        return value.to_i.to_f
      end
    end

    # Converts a value to a floating point number.
    # @deprecated Use {::Object#to_f} instead
    def self.tofloat value
      return nil if value.nil?

      return value.to_f
    rescue
      return nil
    end

    ###########################################################
    # Yast Integer Builtins
    ###########################################################

    # Converts a value to an integer.
    # @note recommended to replace by {::String#to_i} but behavior is slightly different
    def self.tointeger object
      return nil if object.nil?

      case object
      when ::String
        # ideally this should be enought: object.scanf("%i").first
        # but to be 100% Yast compatible we need to do this,
        # see https://github.com/yast/yast-core/blob/master/libyast/src/YastInteger.cc#L39
        if object[0] == "0"
          return object.scanf((object[1] == "x") ? "%x" : "%o").first
        end
        object.scanf("%d").first
      # use full qualified ::Float to avoid clash with Yast::Builtins::Float
      when ::Float, ::Fixnum, ::Bignum
        object.to_i
      else
        nil
      end
    end

    # contains() Yast built-in
    # Checks if a list contains an element
    # @deprecated Use {::Array#include?}
    def self.contains list, value
      return nil if list.nil? || value.nil?
      list.include? value
    end

    # Flattens List
    # @deprecated Use {::Array#flatten} but be aware different behavior for nil in Array
    def self.flatten value
      return nil if value.nil?

      return value.reduce([]) do |acc,i|
        return nil if i.nil?
        acc.push *Yast.deep_copy(i)
      end
    end

    # builtins enclosed in List namespace
    module List
      # Reduces a list to a single value.
      # @deprecated use {::Array#reduce} instead
      def self.reduce *params, &block
        return nil if params.first.nil?
        list = if params.size == 2 #so first is default and second is list
            return nil if params[1].nil?
            [params.first].concat(Yast.deep_copy(params[1]))
          else
            params.first
          end
        return Yast.deep_copy(list).reduce &block
      end


      # Creates new list with swaped elements at offset i1 and i2.
      # @note #{::Array#reverse} should be used for complete array swap
      def self.swap list, offset1, offset2
        return nil if list.nil? || offset1.nil? || offset2.nil?

        return Yast.deep_copy(list) if offset1 < 0 || offset2 >= list.size || (offset1 > offset2)

        res = []
        if offset1 > 0
          res.concat list[0..offset1-1]
        end
        res.concat list[offset1..offset2].reverse!
        if offset2 < list.size-1
          res.concat list[offset2+1..-1]
        end
        return Yast.deep_copy(res)
      end
    end

    # Maps an operation onto all elements of a list and thus creates a map.
    # @deprecated for mapping of list to hash use various ruby builtins like {::Hash.[]} or {::Enumerable#reduce}
    def self.listmap list, &block
      return nil if list.nil?

      res = ::Hash.new
      begin
        Yast.deep_copy(list).each do |i|
          res.merge! block.call(i)
        end
      rescue Yast::Break
        #break stops adding to hash
      end

      return res
    end

    # Sort A List respecting locale
    # @deprecated use {::Array#sort} but be aware differences between ruby and old ycp sorting
    # @see Yast::Ops#comparable_object for details how it sorts
    def self.lsort list
      return nil if list.nil?

      Yast.deep_copy(list.sort { |s1, s2| Ops.comparable_object(s1, true) <=> s2 })
    end

    # merge() Yast built-in
    # Merges two lists into one
    # @deprecated use {::Array#+}
    def self.merge a1, a2
      return nil if a1.nil? || a2.nil?
      Yast.deep_copy(a1 + a2)
    end

    # Prepends a list with a new element
    # @deprecated use {::Array#unshift}
    def self.prepend list, element
      return nil if list.nil?

      return [Yast.deep_copy(element)].push *Yast.deep_copy(list)
    end

    # setcontains() Yast built-in
    # Checks if a sorted list contains an element
    # @deprecated use {::Array#include?}
    def self.setcontains list, value
      # simply call contains(), setcontains() is just optimized contains() call
      contains list, value
    end

    # sort() Yast built-in
    # Sorts a List according to the Yast builtin predicate
    # @deprecated use {::Array#sort} but be aware differences between ruby and old ycp sorting
    # @see Yast::Ops#comparable_object for details how it sorts
    def self.sort array, &block
      return nil if array.nil?

      res = if block_given?
        array.sort { |x,y| block.call(x,y) ? -1 : 1 }
      else
        array.sort {|x,y| Yast::Ops.comparable_object(x) <=> y }
      end

      Yast.deep_copy(res)
    end

    # splitstring() Yast built-in
    # Split a string by delimiter
    # @deprecated use {::String#split} but note that ycp version keep empty values in list
    def self.splitstring string, sep
      return nil if string.nil? || sep.nil?
      return [] if sep.empty?

      # the big negative value forces keeping empty values in the list
      string.split /[#{Regexp.escape sep}]/, -1 * 2**20
    end

    # @private we must mark somehow default value for length
    DEF_LENGHT = "default"
    # Extracts a sublist
    # - sublist(<list>, <offset>)
    # - sublist(<list>, <offset>, <length>)
    # @deprecated use {::Array#slice} instead
    def self.sublist list, offset, length=DEF_LENGHT
      return nil if list.nil? || offset.nil? || length.nil?

      length = list.size - offset if length==DEF_LENGHT
      return nil if offset < 0 || offset >= list.size
      return nil if length < 0 || offset+length > list.size

      return Yast.deep_copy(list)[offset..offset+length-1]
    end

    # Converts a value to a list (deprecated, use (list)VAR).
    # @deprecated not needed in ruby
    def self.tolist object
      return object.is_a?(::Array) ? object : nil
    end

    # toset() Yast built-in
    # Sorts list and removes duplicates
    # @deprecated use {::Set} type or combination of #{::Array#sort} and #{::Array#uniq}
    def self.toset array
      return nil if array.nil?
      res = array.uniq.sort { |x,y| Yast::Ops.comparable_object(x) <=> y }
      Yast.deep_copy(res)
    end

    ###########################################################
    # Map Builtins
    ###########################################################

    # Check if map has a certain key
    # @deprecated use {::Hash#haskey?}
    def self.haskey map, key
      return nil if map.nil? || key.nil?
      map.key? key
    end

    # Select a map element (deprecated, use MAP[KEY]:DEFAULT)
    # @deprecated
    def self.lookup map, key, default
      map.key?(key) ? Yast.deep_copy(map[key]) : Yast.deep_copy(default)
    end

    # Maps an operation onto all key/value pairs of a map
    # @deprecated use ruby native methods for creating new Hash from other Hash
    def self.mapmap map, &block
      return nil if map.nil?
      unless map.is_a?(Hash)
        raise TypeError, "expected a Hash, got a #{map.class}"
      end

      map = Yast.deep_copy(map)
      res = ::Hash.new
      begin
        sort(map.keys).each do |k|
          res.merge! block.call(k,map[k])
        end
      rescue Yast::Break
        #break stops adding to hash
      end

      return res
    end

    # Converts a value to a map.
    # @deprecated not needed in ruby or use {::Hash.try_convert}
    def self.tomap object
      return object.is_a?(::Hash) ? object : nil
    end

    ###########################################################
    # Miscellaneous Yast Builtins
    ###########################################################

    # Evaluate a Yast value.
    # @deprecated for lazy evaluation use builtin lambda or block calls
    def self.eval object
      if object.respond_to? :call
        return object.call
      else
        return Yast.deep_copy(object)
      end
    end

    # Change or add an environment variable
    # @deprecated use {ENV#[]}
    def self.getenv value
      return ENV[value]
    end

    # Random number generator.
    # @deprecated use {::Kernel#rand}
    def self.random max
      return nil if max.nil?

      return max < 0 ? -rand(max) : rand(max)
    end

    # Change or add an environment variable
    # @deprecated use {ENV#[]=} instead
    def self.setenv env, value, overwrite = true
      return true if ENV.include?(env) && !overwrite

      ENV[env] = value
      return true
    end

    # Yast compatible way how to format string with type conversion
    # see tostring for type conversion
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
            tostring args[pos]
          else
            Yast.y2warning 1, "sformat: Illegal argument number #{match}, maximum is %#{args.size-1}."
            ""
          end
        else
          Yast.y2warning 1, "sformat: Illegal argument number #{match}."
          ""
        end
      end
    end

    # Sleeps a number of milliseconds.
    # @deprecated use {::Kernel#sleep} instead. For miliseconds divide number by 1000.0.
    def self.sleep milisecs
      # ruby sleep() accepts seconds (float)
      ::Kernel.sleep milisecs / 1000.0
    end

    # time() Yast built-in
    # Return the number of seconds since 1.1.1970.
    # @deprecated use ```::Time.now.to_i``` instead
    def self.time
      ::Time.now.to_i
    end

    # Log a message to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2debug *args
      shift_frame_number args
      Yast.y2debug *args
    end

    # Log an error to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2error *args
      shift_frame_number args
      Yast.y2error *args
    end

    # Log an internal message to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2internal *args
      shift_frame_number args
      Yast.y2internal *args
    end

    # Log a milestone to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2milestone*args
      shift_frame_number args
      Yast.y2milestone *args
    end

    # Log a security message to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2security *args
      shift_frame_number args
      Yast.y2security *args
    end

    # Log a warning to the y2log.
    # @deprecated Use {Yast::Logger} instead
    def self.y2warning *args
      shift_frame_number args
      Yast.y2warning *args
    end

    # @private used only internal for frame shifting
    def self.shift_frame_number args
      if args.first.is_a? ::Fixnum
        args[0] += 1 if args[0] >= 0
      else
        args.unshift 1
      end
    end

    # Log an user-level system message to the y2changes
    # @note do nothing now, concept is quite unclear
    def self.y2useritem *args
      # TODO implement it
      return nil
    end

    # Log an user-level addional message to the y2changes
    # @note do nothing now, concept is quite unclear
    def self.y2usernote *args
      # TODO implement it
      return nil
    end

    ###########################################################
    # Yast Path Builtins
    ###########################################################

    # Converts a value to a path.
    # @deprecated for conversion from String use directly {Yast::Path} methods
    def self.topath object
      case object
      when Yast::Path
        return object
      when ::String
        object = "."+object unless object.start_with?(".")
        return Yast::Path.new(object)
      else
        return nil
      end
    end

    ###########################################################
    # Yast ::String Builtins
    # crypt* builtins implemented in C part
    ###########################################################

    # Removes all characters from a string
    # @deprecated use ruby native method for string handling like {::String#gsub} or {::String#delete}
    def self.deletechars string, chars
      return nil if !string || !chars

      return string.gsub(/[#{Regexp.escape chars}]/, "")
    end

    extend Yast::I18n
    # Translates the text using the given text domain
    def self.dgettext (domain, text)
      old_text_domain = FastGettext.text_domain
      textdomain domain
      return _(text)
    ensure
      FastGettext.text_domain = old_text_domain
      textdomain old_text_domain
    end

    # Translates the text using a locale-aware plural form handling
    def self.dngettext (domain, singular, plural, num)
      old_text_domain = FastGettext.text_domain
      textdomain domain
      return n_(singular, plural, num)
    ensure
      FastGettext.text_domain = old_text_domain
      textdomain old_text_domain
    end

    # Translates the text using the given text domain and path
    def self.dpgettext (domain, dirname, text)
      old_text_domain = FastGettext.text_domain

      # remember the domain => file mapping, the same domain might be
      # used from a different path, then we need to reload the translations
      @textdomain_mapping ||= {}

      # check if the domain is already loaded from the path
      if @textdomain_mapping[domain] != dirname && !FastGettext.translation_repositories[domain]
        FastGettext.add_text_domain(domain, :path => dirname)
        @textdomain_mapping[domain.dup] = dirname.dup
      end
      FastGettext.text_domain = domain
      return FastGettext::Translation._(text)
    ensure
      FastGettext.text_domain = old_text_domain
    end

    # Filters characters out of a ::String
    # @deprecated use ruby native method for string handling like {::String#gsub} or {::String#delete}
    def self.filterchars string, chars
      return nil if string.nil? || chars.nil?

      return string.gsub(/[^#{Regexp.escape chars}]/, "")
    end

    # Searches string for the first non matching chars
    # @deprecated use {::String#index} instead
    def self.findfirstnotof string, chars
      return nil if string.nil? || chars.nil?

      return string.index /[^#{Regexp.escape chars}]/
    end

    # Finds position of the first matching characters in string
    # @deprecated use {::String#index} instead
    def self.findfirstof string, chars
      return nil if string.nil? || chars.nil?

      return string.index /[#{Regexp.escape chars}]/
    end

    # Searches the last element of string that doesn't match
    # @deprecated use {::String#rindex} instead
    def self.findlastnotof string, chars
      return nil if string.nil? || chars.nil?

      return string.rindex /[^#{Regexp.escape chars}]/
    end

    # Searches string for the last match
    # @deprecated use {::String#rindex} instead
    def self.findlastof string, chars
      return nil if string.nil? || chars.nil?

      return string.rindex /[#{Regexp.escape chars}]/
    end

    # issubstring() Yast built-in
    # searches for a specific string within another string
    # @deprecated use {::String#include?} instead
    def self.issubstring string, substring
      return nil if string.nil? || substring.nil?
      string.include? substring
    end

    # Extracts a substring in UTF-8 encoded string
    # @deprecated use {::String#include?} instead
    def self.lsubstring string, offset, length = -1
      #ruby2.0 use by default UTF-8.
      substring string, offset, length
    end

    # mergestring() Yast built-in
    # Joins list elements with a string
    # @deprecated use {::String#join} instead
    def self.mergestring string, sep
      return nil if string.nil? || sep.nil?

      string.join sep
    end

    # Returns position of a substring (nil if not found)
    # @deprecated use {::String#index} instead
    def self.search string, substring
      return nil if string.nil? || substring.nil?
      string.index substring
    end

    # substring() Yast built-in
    # Extracts a substring
    # little bit complicated because Yast returns different values
    # in corner cases (nil or negative parameters, out of range...)
    # @deprecated use {::String#[]} instead
    def self.substring string, offset, length = -1
      return nil if string.nil? || offset.nil? || length.nil?
      return "" if offset < 0 || offset >= string.size

      length = string.size - offset if length < 0

      string[offset, length]
    end

    # Returns time string
    # @deprecated use {::Time#strftime} instead
    def self.timestring format, time, utc
      return nil if format.nil? || time.nil? || utc.nil?

      t = Time.at time
      t = t.utc if utc

      t.strftime format
    end

    # Gets new string including only characters below 0x7F
    def self.toascii string
      return nil if string.nil?

      ret = ""
      string.each_char { |c| ret << c if c.ord < 0x7f }
      ret
    end

    # Converts an integer to a hexadecimal string.
    # - tohexstring(<int>)
    # - tohexstring(<int>, <int>width)
    # @deprecated use {::Fixnum#to_s} with base 16 instead but note that there is slight differences
    def self.tohexstring int, width = 0
      return nil if int.nil? || width.nil?

      if int >= 0
        sprintf("0x%0#{width}x", int)
      else
        # compatibility for negative numbers
        # Ruby: -3 => '0x..fd'
        # Yast:  -3 => '0xfffffffffffffffd' (64bit integer)

        # this has '..fff' prefix
        ret = sprintf("%018x", int)

        # pad with zeroes or spaces if needed
        if width > 16
          ret.insert(2, "0" * (width - 16))
        elsif width < -16
          ret << (" " * (-width - 16))
        end

        # replace the ".." prefix by "0x"
        ret[0..1] = "0x"
        ret
      end
    end

    # tolower() Yast built-in
    # Makes a string lowercase
    # @deprecated use {::String#downcase} instead
    def self.tolower string
      return nil if string.nil?
      string.downcase
    end

    # Converts a value to a string in ycp.
    # @deprecated There is no strong reason to use this instead of inspect
    def self.tostring val, width=nil
      if width
        raise "tostring: negative 'width' argument: #{width}" if width < 0

        return "%.#{width}f" % val
      end

      case val
      # string behavior depends if it is used inside something of alone
      when ::String then val
      when ::Symbol then "`#{val}"
      when ::Proc then "\"Annonymous method\""
      when Yast::YCode then "\"Remote code\""
      when ::NilClass then "nil"
      when ::TrueClass then "true"
      when ::FalseClass then "false"
      when ::Fixnum,
           ::Bignum,
           ::Float,
           Yast::Term,
           Yast::Path,
           Yast::External,
           Yast::Byteblock
        val.to_s
      when ::Array then "[#{val.map{|a|inside_tostring(a)}.join(", ")}]"
      when ::Hash then "$[#{sort(val.keys).map{|k|"#{inside_tostring(k)}:#{inside_tostring(val[k])}"}.join(", ")}]"
      when Yast::FunRef
        # TODO FIXME: Yast puts also the parameter names,
        # here the signature contains only data type without parameter name:
        #   Yast:    <YCPRef:boolean foo (string str, string str2)>
        #   Ruby:    <YCPRef:boolean foo (string, string)>
        #
        # There is also extra "any" in lists/maps:
        #   Yast:    <YCPRef:list <map> bar (list <map> a)>
        #   Ruby:    <YCPRef:list <map<any,any>> bar (list <map<any,any>>)>
        val.signature.match /(.*)\((.*)\)/
        "<YCPRef:#{$1}#{val.remote_method.name} (#{$2})>"
      else
        y2warning 1, "tostring builtin called on wrong type #{val.class}"
        return val.inspect
      end
    end

    # @private string is handled diffent if string is inside other structure
    def self.inside_tostring val
      if val.is_a? ::String
        return val.inspect
      else
        tostring val
      end
    end

    # toupper() Yast built-in
    # Makes a string uppercase
    # @deprecated use {::String#upcase} instead
    def self.toupper string
      return nil if string.nil?
      string.upcase
    end

    ###########################################################
    # Documentation of methods implemented in C is here
    # because I could not figure out how to make yard parse it there.

    # @method self.regexpmatch(string, pattern)
    #
    # @param string [String] a string to search
    # @param pattern [String] a regex in the C(!) syntax
    # @return [Boolean, nil] does *string* match *pattern*
    # @deprecated use string =~ pattern
    #
    # Searches a string for a POSIX Extended Regular Expression match.
    #
    # If *string* or *pattern* is `nil`, or
    # if pattern is an invalid regex, `nil` is returned.
    #
    # **Replacement**
    #
    # Notably `^` and `$` match the ends of the entire string,
    # not each line like in Regexp. Use /\A/ and /\z/
    # (There is also /\Z/ which matches before a final newline.)
    #
    # The dot `.` does match a newline. Use `/pattern/m`.
    #
    # To match a literal dot, replace a double backslash `"\\."`
    # with a single backslash `/\./`
    #
    # Literal brackets inside character classes need a backslash
    # (gh#yast/yast-ruby-bindings#10)
    #
    # Unfortunately regexp dialects are full of subtle differences
    # like this. See  http://www.regular-expressions.info/refflavors.html
    # and do test.
    #
    # **Idiomatic Replacement**
    #
    # In a condition, use `string =~ pattern` which returns integer or nil.

    ###########################################################
    # Yast Term Builtins
    ###########################################################

    # Returns the arguments of a term.
    # @deprecated use {Yast::Term#params} instead
    def self.argsof term
      return nil if term.nil?

      return Yast.deep_copy(term.params)
    end

    # Returns the symbol of the term TERM.
    # @deprecated use {Yast::Term#value} instead
    def self.symbolof term
      return nil if term.nil?

      return term.value
    end


    # Converts a value to a term.
    # @deprecated use {Yast::Term} constructor instead
    def self.toterm symbol, list=DEF_LENGHT
      return nil if symbol.nil? || list.nil?

      case symbol
      when ::String
        return Yast::Term.new(symbol.to_sym)
      when ::Symbol
        if list==DEF_LENGHT
          return Yast::Term.new(symbol)
        else
          return Yast::Term.new(symbol,*list)
        end
      when Yast::Term
        return symbol
      end
    end

    # @deprecated use #{::String#to_sym} instead
    def self.tosymbol value
      return nil if value.nil?

      return value.to_sym
    end

    # builtins enclosed in Multiset namespace
    # @deprecated use ruby type {::Set} instead or difference library for set handling
    module Multiset
      # @see http://www.sgi.com/tech/stl/includes.html for details
      def self.includes set1, set2
        #cannot use to_set because there is difference if there is element multipletime
        repetition = {}
        set2.all? do |e|
          repetition[e] ||= 0
          repetition[e] += 1
          set1.count(e) >= repetition[e]
        end
      end

      # @see http://www.sgi.com/tech/stl/set_difference.html for details
      def self.difference set1, set2
        Yast.deep_copy(set1.to_set - set2.to_set).to_a
      end

      # @see http://www.sgi.com/tech/stl/set_symmetric_difference.html for details
      def self.symmetric_difference set1, set2
        ss1 = set1.sort
        ss2 = set2.sort
        res = []
        while !(ss1.empty? || ss2.empty?) do
          i1 = ss1.last
          i2 = ss2.last
          case i1 <=> i2
          when -1
            res << i2
            ss2.pop
          when 1
            res << i1
            ss1.pop
          when 0
            ss1.pop
            ss2.pop
          else
            raise "unknown value from comparison #{i1 <=> u2}"
          end
        end
        unless ss1.empty?
          res = res + ss1.reverse
        end
        unless ss2.empty?
          res = res + ss2.reverse
        end
        return Yast.deep_copy(res.reverse)
      end

      # @see http://www.sgi.com/tech/stl/set_intersection.html for details
      def self.intersection set1, set2
        ss1 = set1.sort
        ss2 = set2.sort
        res = []
        while !(ss1.empty? || ss2.empty?) do
          i1 = ss1.last
          i2 = ss2.last
          case i1 <=> i2
          when -1
            ss2.pop
          when 1
            ss1.pop
          when 0
            res << i1
            ss1.pop
            ss2.pop
          else
            raise "unknown value from comparison #{i1 <=> u2}"
          end
        end
        return Yast.deep_copy(res.reverse)
      end

      # @see http://www.sgi.com/tech/stl/set_union.html for details
      def self.union set1, set2
        ss1 = set1.sort
        ss2 = set2.sort
        res = []
        while !(ss1.empty? || ss2.empty?) do
          i1 = ss1.last
          i2 = ss2.last
          case i1 <=> i2
          when -1
            res << i2
            ss2.pop
          when 1
            res << i1
            ss1.pop
          when 0
            res << i1
            ss1.pop
            ss2.pop
          else
            raise "unknown value from comparison #{i1 <=> u2}"
          end
        end

        unless ss1.empty?
          res = res + ss1.reverse
        end
        unless ss2.empty?
          res = res + ss2.reverse
        end

        return Yast.deep_copy(res.reverse)
      end

      # @see http://www.sgi.com/tech/stl/set_merge.html for details
      def self.merge set1, set2
        Yast.deep_copy(set1 + set2)
      end
    end
  end
end
