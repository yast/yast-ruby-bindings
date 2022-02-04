require "yast/yast"
require "yast/path"
require "yast/logger"

module Yast
  # predefine term to avoid circular dependency
  class Term; end
  class FunRef; end
  class YReference; end
  class Byteblock; end

  # These emulate the YCP arithmetic and logic operators.
  # In particular, `nil` as an argument mostly propagates to the results.
  # You will probably want to check for `nil` beforehand
  # and then use the normal Ruby operators.
  module Ops
    # map of YCPTypes to ruby types
    TYPES_MAP = {
      "any"       => ::Object,
      "nil"       => ::NilClass,
      "void"      => ::NilClass,
      "boolean"   => [::TrueClass, ::FalseClass],
      "string"    => ::String,
      "symbol"    => ::Symbol,
      "integer"   => ::Integer,
      "float"     => ::Float,
      "list"      => ::Array,
      "map"       => ::Hash,
      "term"      => Yast::Term,
      "path"      => Yast::Path,
      "locale"    => ::String,
      "function"  => [Yast::FunRef, Yast::YReference],
      "byteblock" => Yast::Byteblock
    }.freeze

    # Types for which we generate shortcut methods,
    # e.g. {Yast::Ops.get_string}
    # or   {Yast::Convert.to_string}.
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
    ].freeze

    # @!method                    self.get_boolean(       obj, idx, def )
    #   @return [Boolean, nil] {Convert.to_boolean}({get}(obj, idx, def))
    # @!method                     self.get_string(       obj, idx, def )
    #   @return [String, nil]   {Convert.to_string}({get}(obj, idx, def))
    # @!method                     self.get_symbol(       obj, idx, def )
    #   @return [Symbol, nil]   {Convert.to_symbol}({get}(obj, idx, def))
    # @!method                    self.get_integer(       obj, idx, def )
    #   @return [Integer, nil] {Convert.to_integer}({get}(obj, idx, def))
    # @!method                      self.get_float(       obj, idx, def )
    #   @return [Float, nil]     {Convert.to_float}({get}(obj, idx, def))
    # @!method                       self.get_list(       obj, idx, def )
    #   @return [Array, nil]      {Convert.to_list}({get}(obj, idx, def))
    # @!method                        self.get_map(       obj, idx, def )
    #   @return [Hash, nil]        {Convert.to_map}({get}(obj, idx, def))
    # @!method                       self.get_term(       obj, idx, def )
    #   @return [Term, nil]       {Convert.to_term}({get}(obj, idx, def))
    # @!method                       self.get_path(       obj, idx, def )
    #   @return [Path, nil]       {Convert.to_path}({get}(obj, idx, def))
    # @!method                     self.get_locale(       obj, idx, def )
    #   @return [String, nil]   {Convert.to_locale}({get}(obj, idx, def))
    Ops::SHORTCUT_TYPES.each do |type|
      define_singleton_method("get_#{type}") do |object, indexes, default=nil, &block|
        Yast::Convert.public_send("to_#{type}", get(object, indexes, default, 1, &block))
      end
    end

    # To log the caller frame we need to skip 3 frames as 1 is method itself
    # and each block contributes 2 frames (outer: called, inner: defined)
    # Try for yourself:
    #   def a
    #     puts caller.inspect
    #     [0].each { |i| puts caller.inspect }
    #   end
    #   a
    OUTER_LOOP_FRAME = 3

    # @deprecated Use the native Ruby operator `[]`
    #
    # Gets value from *object* at *indexes*.
    # Eager to return *default* at slightest provocation.
    #
    # **Replacement**
    #
    # Consider using
    #
    # - `object[index]`
    # - `object[i1][i2]`
    # - `object[index] || default` if the value cannot be `false` or `nil`
    # - `object.fetch(index, default)`
    # - `object.fetch(index)` if you want an exception when index is absent
    #
    # @param object [Array, Hash, Yast::Term]
    # @param indexes Usually a scalar, but also an array of scalars
    #    to recursively descend into *object*
    # @param default the default value returned (via {deep_copy}) for any error;
    #    if a **block** is given, it is called to provide the default value
    #    (only when the default is needed, so it is useful for values
    #    that are expensive to compute).
    # @param skip_frames [Integer] private, how many caller frames to skip
    #  when reporting warnings or exceptions
    #
    # @return The value in *object* at *indexes*, if it exists.
    #    The *default* value if *object*, *indexes* are nil, have wrong type,
    #    or *indexes* does not exist in *object*.
    def self.get(object, indexes, default = nil, skip_frames = 0)
      res = object
      default = Yast.deep_copy(default)
      skip_frames += OUTER_LOOP_FRAME
      indexes = [indexes] unless indexes.is_a? ::Array

      indexes.each do |i|
        case res
        when ::Array, Yast::Term
          if i.is_a?(::Integer)
            if (0..res.size - 1).cover? i
              res = res[i]
            else
              Yast.y2milestone skip_frames, "Index #{i} is out of array size"
              return block_given? ? yield : default
            end
          else
            Yast.y2warning skip_frames, "Passed #{i.inspect} as index key for array."
            return block_given? ? yield : default
          end
        when ::Hash
          return block_given? ? yield : default unless res.key?(i)

          res = res[i]
        when ::NilClass
          Yast.y2milestone skip_frames, "Ops.get called on nil."
          return block_given? ? yield : default
        else
          Yast.y2warning skip_frames, "Ops.get called on wrong type #{res.class}"
          return block_given? ? yield : default
        end
      end
      Yast.deep_copy(res)
    end

    # @deprecated Use the native Ruby operator `[]=`
    #
    # Sets *value* to *object* at given *indexes*.
    #
    # If *object* or *indexes* is `nil`, `set` does nothing.
    #
    # If *indexes* is an Array, `set` recursively descends
    # through all but last indexes to find the destination container.
    # As expected, if the last index does not exist,
    #              *object* is assigned.
    # However, if an intermediate index does not exist,
    #          *object* is **not** asigned (no Perl-like autovivification).
    #
    # **Replacement**
    #
    # `Ops.set(object, indexes, value)`
    #   can be mechanically replaced by
    # `object[indexes] = value`
    # if **all** conditions below are met
    #
    # - *object* is a non-nil Array, Hash, {Yast::Term}
    # - *indexes* is a non-nil scalar
    # - *value* does not need {deep_copy}
    #
    # **Idiomatic Replacement**
    #
    # If you want cleaner code and are ready to rescue exceptions, this applies:
    #
    # - *object* will simply raise an error if it cannot handle `[]=`;
    #   that works as expected.
    # - If *indexes* is an Array of the form [i, j, k],
    #   use `object[i][j][k] = value`.
    #   Missing indexes will become `nil` and raise an exception
    #   on the next index.
    # - *value* may need a deep copy: `object[indexes] = deep_copy(value)`
    #
    # @return [void]
    def self.set(object, indexes, value)
      return if indexes.nil? || object.nil?

      indexes = [indexes] unless indexes.is_a? ::Array
      last = indexes.pop
      res = object

      # return here is needed for quick exit of method and workaround with any or
      # all is nasty and decrease readability
      # rubocop:disable Lint/NonLocalExitFromIterator
      indexes.each do |i|
        case res
        when ::Array, Yast::Term
          if !i.is_a?(::Integer)
            Yast.y2warning OUTER_LOOP_FRAME, "Passed #{i.inspect} as index key for array."
            return
          end

          if !(0..res.size - 1).cover?(i)
            Yast.y2warning OUTER_LOOP_FRAME, "Index #{i} is out of array size"
            return
          end

          res = res[i]
        when ::Hash
          return unless res.key? i

          res = res[i]
        else
          Yast.y2warning OUTER_LOOP_FRAME, "Builtin assign called on wrong type #{res.class}"
          return
        end
      end
      # rubocop:enable Lint/NonLocalExitFromIterator

      case res
      when ::Array, Yast::Term, ::Hash
        res[last] = Yast.deep_copy(value)
      else
        # log is not in loop, so use simple 1 to get outside of method
        Yast.y2warning 1, "Builtin assign called on wrong type #{res.class}"
      end
    end

    # Adds second to first.
    # @deprecated use ruby native operator +
    def self.add(first, second)
      return nil if first.nil? || second.nil?

      case first
      when ::Array
        return Yast.deep_copy(first + second) if second.is_a?(::Array)

        Yast.deep_copy(first).push(Yast.deep_copy(second))
      when ::Hash
        Yast.deep_copy(first).merge(Yast.deep_copy(second))
      when ::String
        first + second.to_s
      else
        first + second
      end
    end

    # Subtracts second from first.
    # @deprecated use ruby native operator -
    def self.subtract(first, second)
      return nil if first.nil? || second.nil?

      first - second
    end

    # Multiplies first with second.
    # @deprecated use ruby native operator *
    def self.multiply(first, second)
      return nil if first.nil? || second.nil?

      first * second
    end

    # Divides first with second.
    # @deprecated use ruby native operator /
    # @note allows division with zero and in such case return nil
    def self.divide(first, second)
      return nil if first.nil? || second.nil? || second == 0

      first / second
    end

    # Computes module after division of first with second.
    # @deprecated use ruby native operator %
    def self.modulo(first, second)
      return nil if first.nil? || second.nil?

      first % second
    end

    # @deprecated use ruby native operator &
    def self.bitwise_and(first, second)
      return nil if first.nil? || second.nil?

      first & second
    end

    # @deprecated use ruby native operator |
    def self.bitwise_or(first, second)
      return nil if first.nil? || second.nil?

      first | second
    end

    # @deprecated use ruby native operator ^
    def self.bitwise_xor(first, second)
      return nil if first.nil? || second.nil?

      first ^ second
    end

    # @deprecated use ruby native operator <<
    def self.shift_left(first, second)
      return nil if first.nil? || second.nil?

      first << second
    end

    # @deprecated use ruby native operator >>
    def self.shift_right(first, second)
      return nil if first.nil? || second.nil?

      first >> second
    end

    # @deprecated use ruby native operator &&
    def self.logical_and(first, second)
      first = false if first.nil?
      second = false if second.nil?

      first && second
    end

    # @deprecated use ruby native operator ||
    def self.logical_or(first, second)
      first = false if first.nil?
      second = false if second.nil?

      first || second
    end

    # @deprecated use ruby native operator -
    def self.unary_minus(value)
      return nil if value.nil?

      -value
    end

    # @deprecated use ruby native operator !
    # @note for nil returns nil to be compatible with ycp implementation
    def self.logical_not(value)
      # Yast really do it!!!
      return nil if value.nil?

      !value
    end

    # @deprecated use ruby native operator ~
    def self.bitwise_not(value)
      return nil if value.nil?

      ~value
    end

    # @deprecated use ruby native operator ==
    def self.equal(first, second)
      first = comparable_object(first)

      first == second
    end

    # @deprecated use ruby native operator !=
    def self.not_equal(first, second)
      first = comparable_object(first)

      first != second
    end

    # @deprecated use ruby native operator <
    def self.less_than(first, second)
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      first < second
    end

    # @deprecated use ruby native operator <=
    def self.less_or_equal(first, second)
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      first <= second
    end

    # @deprecated use ruby native operator >
    def self.greater_than(first, second)
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      first > second
    end

    # @deprecated use ruby native operator >=
    def self.greater_or_equal(first, second)
      return nil if first.nil? || second.nil?

      first = comparable_object(first)

      first >= second
    end

    TYPES_MAP.keys.each do |type|
      define_singleton_method("is_#{type}?") do |object|
        Ops.is(object, type)
      end
    end

    # Checks if object is given YCP type. There is also shorfcuts for most of types in
    # format is_<type>
    def self.is(object, type)
      type = "function" if type =~ /\(.*\)/ # reference to function
      type = type.gsub(/<.*>/, "")
      type = type.gsub(/\s+/, "")
      classes = TYPES_MAP[type]
      raise "Invalid type to detect in is '#{type}'" unless classes
      classes = [classes] unless classes.is_a? ::Array
      classes.any? { |cl| object.is_a? cl }
    end

    # Creates comparable wrapper that makes ycp compatible comparison
    def self.comparable_object(object, localized = false)
      GenericComparable.new(object, localized)
    end

    # Implements ycp compatible comparison of lists. Difference is only that it use {Yast::Ops::GenericComparator}
    # for each of its element.
    # @deprecated array usually don't need comparing
    class ListComparator
      include Comparable
      def initialize(value, localized = false)
        @value = value
        @localized = localized
      end

      def <=>(other)
        min_size = [@value.size, other.size].min
        0.upto(min_size - 1) do |i|
          # stupid nil handling
          fval = @value[i]
          sval = other[i]

          return 1 if sval.nil? && !fval.nil?

          # we need to use out builtin, but also we need to
          res = Ops.comparable_object(fval, @localized) <=> sval
          return res if res != 0
        end
        # no decision yet
        @value.size <=> other.size
      end
    end

    # Implements ycp compatible comparison of Hash. It uses lexical comparison for keys and elements.
    # @deprecated hash comparison usually doesn't make sense
    class HashComparator
      include Comparable
      def initialize(value, localized = false)
        @value = value
        @localized = localized
      end

      def <=>(other)
        comparator = proc do |k1, k2|
          Ops.comparable_object(k1, @localized) <=> k2
        end
        keys = @value.keys.sort(&comparator)
        other_keys = other.keys.sort(&comparator)

        0.upto(keys.size - 1) do |i|
          res = Ops.comparable_object(keys[i], @localized) <=> other_keys[i]
          return res if res != 0

          res = Ops.comparable_object(@value[keys[i]], @localized) <=> other[keys[i]]
          return res if res != 0
        end

        @value.size <=> other.size
      end
    end

    # Generic comparator that can compare various classes together like yast, order is based on yast class order.
    # @deprecated use native ruby comparing, comparing various class usually is not usable.
    class GenericComparable
      include Comparable

      def initialize(value, localized = false)
        @value = value
        @localized = localized
      end
      # ordered classes from low priority to high
      CLASS_ORDER = [::NilClass, ::FalseClass, ::TrueClass, ::Integer, ::Float,
                     ::String, Yast::Path, ::Symbol, ::Array, Yast::Term, ::Hash].freeze
      def <=>(other)
        if @value.class == other.class
          case @value
          when ::Array
            ListComparator.new(@value, @localized) <=> other
          when ::NilClass
            0 # comparison of two nils is equality
          when ::Hash
            HashComparator.new(@value, @localized) <=> other
          when ::String
            @localized ? Yast.strcoll(@value, other) : (@value <=> other)
          else
            @value <=> other
          end
        else
          return @value <=> other if @value.is_a?(::Numeric) && other.is_a?(::Numeric)

          # workaround for older ruby versions which have value.is_a?(Integer) but value.class => Fixnum
          # No longer problem with ruby 2.4
          order = CLASS_ORDER.index(@value.class) || CLASS_ORDER.index(::Integer)
          other_order = CLASS_ORDER.index(other.class) || CLASS_ORDER.index(::Integer)
          order <=> other_order
        end
      end
    end
  end
end
