require "yast/ops"
require "yast/path"
require "yast/term"
require "yast/logger"

module Yast
  # Wrapper to simulate behavior of type conversion in YCP.
  # there is generated shortcuts for conversion to_<type>
  # @deprecated ruby need not type conversion and int<->float conversion is explicit
  module Convert
    # @!method  self.to_boolean(       object )
    #   @return        [Boolean, nil] *object*, or `nil` if it is not `true` or `false`
    # @!method  self.to_string(        object )
    #   @see Builtins.tostring
    #   @return        [String, nil]  *object*, or `nil` if it is not a String
    # @!method  self.to_symbol(        object )
    #   @see Builtins.tosymbol
    #   @return        [Symbol, nil]  *object*, or `nil` if it is not a Symbol
    # @!method  self.to_integer(       object )
    #   @see Builtins.tointeger
    #   @return        [Integer, nil] *object*, or `nil` if it is not a Integer
    # @!method  self.to_float(         object )
    #   @see Builtins.tofloat
    #   @return        [Float, nil]   *object*, or `nil` if it is not a Float
    # @!method  self.to_list(          object )
    #   @see Builtins.tolist
    #   @return        [Array, nil]   *object*, or `nil` if it is not a Array
    # @!method  self.to_map(           object )
    #   @see Builtins.tomap
    #   @return        [Hash, nil]    *object*, or `nil` if it is not a Hash
    # @!method  self.to_term(          object )
    #   @see Builtins.toterm
    #   @return        [Term, nil]    *object*, or `nil` if it is not a Term
    # @!method  self.to_path(          object )
    #   @see Builtins.topath
    #   @return        [Path, nil]    *object*, or `nil` if it is not a Path
    # @!method  self.to_locale(        object )
    #   @return        [String, nil]  *object*, or `nil` if it is not a String
    Ops::SHORTCUT_TYPES.each do |type|
      eval <<END
        def self.to_#{type}(object)
          convert object, :from => "any", :to => "#{type}"
        end
END
    end

    # Converts object from given type to target one.
    def self.convert(object, options)
      from = options[:from].dup
      to = options[:to].dup

      #ignore whitespaces and specialization in types
      to.gsub!(/<.*>/, "")
      to.gsub!(/\s+/, "")
      from.gsub!(/<.*>/, "")
      from.gsub!(/\s+/, "")

      # reference to function
      to = "function" if to =~ /\(.*\)/

      raise "missing parameter :from" unless from
      raise "missing parameter :to" unless to

      return nil if object.nil?
      return object if from == to

      if from == "any" && allowed_type(object,to)
        return object
      elsif to == "float"
        return nil unless (object.is_a? Fixnum) || (object.is_a? Bignum)
        return object.to_f
      elsif to == "integer"
        return nil unless object.is_a? Float
        Yast.y2warning "Conversion from integer to float lead to loose precision."
        return object.to_i
      elsif to == "locale" && from == "string"
        return object
      elsif to == "string" && from == "locale"
        return object
      else
        Yast.y2warning -1, "Cannot convert #{object.class} from '#{from}' to '#{to}'"
        return nil
      end
    end

    # @private
    def self.allowed_type(object, to)
      types = Ops::TYPES_MAP[to]
      raise "Unknown type '#{to}' for conversion" if types.nil?

      types = [types] unless types.is_a? Array

      return types.any? {|t|  object.is_a? t }
    end
  end
end

