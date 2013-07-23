require "yast/yast"
require "yast/path"
require "yast/logger"

#predefine term to avoid circular dependency
class Yast::Term;end
class Yast::FunRef;end
class Yast::YReference;end
class Yast::Byteblock;end

module Yast
  module Ops
    #TODO investigate if convert also get more complex typesfor map and list
    TYPES_MAP = {
      'any' => ::Object,
      'nil' => ::NilClass,
      'void' => ::NilClass,
      'boolean' => [::TrueClass,::FalseClass],
      'string' => ::String,
      'symbol' => ::Symbol,
      'integer' => [::Fixnum,::Bignum],
      'float' => ::Float,
      'list' => ::Array,
      'map' => ::Hash,
      'term' => Yast::Term,
      'path' => Yast::Path,
      'locale' => ::String,
      'function' => [Yast::FunRef, Yast::YReference],
      'byteblock' => Yast::Byteblock
    }

    # Types for which we generate shortcut methods, e.g. Ops.get_string or
    # Convert.to_string.
    SHORTCUT_TYPES = [
      "boolean",
      "string",
      "symbol",
      "integer",
      "float",
      "list",
      "map",
      "term",
      "path",
      "locale"
    ]

    Ops::SHORTCUT_TYPES.each do |type|
      eval <<END
        def self.get_#{type}(*args, &block)
          Yast::Convert.to_#{type} get(*args, &block)
        end
END
    end

      def self.get (object, indexes, default=nil)
        res = object
        default = Yast.deep_copy(default)
        indexes = [indexes] unless indexes.is_a? ::Array

        indexes.each do |i|
          case res
          when ::Array, Yast::Term
            if i.is_a? Fixnum
              if (0..res.size-1).include? i
                res = res[i]
              else
                Yast.y2milestone 1, "Index #{i} is out of array size"
                return block_given? ? yield : default
              end
            else
              Yast.y2warning 1, "Passed #{i.inspect} as index key for array."
              return block_given? ? yield : default
            end
          when ::Hash
            if res.has_key? i
              res = res[i]
            else
              return block_given? ? yield : default
            end
          when ::NilClass
            Yast.y2milestone 1, "Builtin index called on nil."
            return block_given? ? yield : default
          else
            Yast.y2warning 1, "Builtin index called on wrong type #{res.class}"
            return block_given? ? yield : default
          end
      end
      return Yast.deep_copy(res)
    end

    def self.set (object, indexes, value)
      return if indexes.nil? || object.nil?

      indexes = [indexes] unless indexes.is_a? ::Array
      last = indexes.pop
      res = object

      indexes.each do |i|
        case res
        when ::Array, Yast::Term
          if i.is_a? Fixnum
            if (0..res.size-1).include? i
              res = res[i]
            else
              Yast.y2warning 1, "Index #{i} is out of array size"
              return
            end
          else
            Yast.y2warning 1, "Passed #{i.inspect} as index key for array."
            return
          end
        when ::Hash
          if res.has_key? i
            res = res[i]
          else
            return
          end
        else
          Yast.y2warning 1, "Builtin assign called on wrong type #{res.class}"
          return
        end
      end
      case res
      when ::Array, Yast::Term, ::Hash
        res[last] = Yast.deep_copy(value)
      else
        Yast.y2warning 1, "Builtin assign called on wrong type #{res.class}"
      end
    end


    def self.add first, second
      return nil if first.nil? || second.nil?

      case first
      when ::Array
        if second.is_a? ::Array
          return Yast.deep_copy(first + second)
        else
          return Yast.deep_copy(first).push(Yast.deep_copy(second))
        end
      when ::Hash
        return Yast.deep_copy(first).merge Yast.deep_copy(second)
      when ::String
        return first + second.to_s
      else
        return first + second
      end
    end

    def self.subtract first, second
      return nil if first.nil? || second.nil?

      return first - second
    end

    def self.multiply first, second
      return nil if first.nil? || second.nil?

      return first * second
    end

    def self.divide first, second
      return nil if first.nil? || second.nil? || second == 0

      return first / second
    end

    def self.modulo first, second
      return nil if first.nil? || second.nil?

      return first % second
    end

    def self.bitwise_and first, second
      return nil if first.nil? || second.nil?

      return first & second
    end

    def self.bitwise_or first, second
      return nil if first.nil? || second.nil?

      return first | second
    end

    def self.bitwise_xor first, second
      return nil if first.nil? || second.nil?

      return first ^ second
    end

    def self.shift_left first, second
      return nil if first.nil? || second.nil?

      return first << second
    end

    def self.shift_right first, second
      return nil if first.nil? || second.nil?

      return first >> second
    end

    def self.logical_and first, second
      first = false if first.nil?
      second = false if second.nil?

      return first && second
    end

    def self.logical_or first, second
      first = false if first.nil?
      second = false if second.nil?

      return first || second
    end

    def self.unary_minus value
      return nil if value.nil?

      return -value
    end

    def self.logical_not value
      #Yast really do it!!!
      return nil if value.nil?

      return !value
    end

    def self.bitwise_not value
      return nil if value.nil?

      return ~value
    end

    def self.equal first, second
      first = comparable_object(first)

      return first == second
    end

    def self.not_equal first, second
      first = comparable_object(first)

      return first != second
    end

    def self.less_than first, second
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      return first < second
    end

    def self.less_or_equal first, second
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      return first <= second
    end

    def self.greater_than first, second
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      return first > second
    end

    def self.greater_or_equal first, second
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      return first >= second
    end

    TYPES_MAP.keys.each do |type|
      class_eval "def self.is_#{type}? (object)
        Ops.is(object, \"#{type}\")
      end"
    end

    def self.is (object, type)
      type = "function" if type =~ /\(.*\)/ #reference to function
      type.gsub!(/<.*>/, "")
      type.gsub!(/\s+/, "")
      classes = TYPES_MAP[type]
      raise "Invalid type to detect in is '#{type}'" unless classes
      classes = [classes] unless classes.is_a? ::Array
      return classes.any? { |cl| object.is_a? cl }
    end

    def self.comparable_object object, localized = false
      return GenericComparable.new(object, localized)
    end

    class ListComparator
      include Comparable
      def initialize value, localized = false
        @value = value
        @localized = localized
      end

      def <=>(second)
        min_size = [@value.size,second.size].min
        0.upto(min_size-1) do |i|
          #stupid nil handling
          fval = @value[i]
          sval = second[i]
          if (sval.nil? && !fval.nil? )
            return 1
          end

          # we need to use out builtin, but also we need to 
          res = Ops.comparable_object(fval, @localized) <=> sval
          return res if res != 0
        end
        # no decision yet
        return @value.size <=> second.size
      end
    end

    class ::HashComparator
      include Comparable
      def initialize value, localized = false
        @value = value
        @localized = localized
      end

      def <=>(second)
        comparator = Proc.new do |k1,k2|
          Ops.comparable_object(k1, @localized) <=> k2
        end
        keys = @value.keys.sort(&comparator)
        other_keys = second.keys.sort(&comparator)

        0.upto(keys.size-1) do |i|
          res = Ops.comparable_object(keys[i], @localized) <=> other_keys[i]
          return res if res != 0

          res = Ops.comparable_object(@value[keys[i]], @localized) <=> second[keys[i]]
          return res if res != 0
        end

        return @value.size <=> second.size
      end
    end

    #speciality of this comparable is that it can compare various classes together like yast, order is based on yast class order
    class GenericComparable
      include Comparable
      
      def initialize value, localized = false
        @value = value
        @localized = localized
      end
      #ordered classes from low priority to high
      # Only tricky part is Fixnum/Bignum, which is in fact same, so it has special handling in code
      CLASS_ORDER = [ ::NilClass, ::FalseClass, ::TrueClass, ::Fixnum, ::Bignum, ::Float, 
        ::String, Yast::Path, ::Symbol, ::Array, Yast::Term, ::Hash ]
      def <=> (second)
        if @value.class == second.class
          case @value
          when ::Array
            return ListComparator.new(@value, @localized) <=> second
          when ::NilClass
            return 0 #comparison of two nils is equality
          when ::Hash
            return ::HashComparator.new(@value, @localized) <=> second
          when ::String
            if @localized
              return Yast.strcoll(@value,second)
            else
              return @value <=> second
            end
          else
            @value <=> second
          end
        else
          if ((@value.class == Fixnum && second.class == Bignum) ||
              @value.class == Bignum && second.class == Fixnum)
            return @value <=> second
          end

          CLASS_ORDER.index(@value.class) <=> CLASS_ORDER.index(second.class)
        end
      end
    end

  end
end
