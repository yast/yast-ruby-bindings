require "ycp/path"
require "ycp/term"
require "ycp/logger"

module Ops
  def self.index (object, indexes, default)
    res = object
    indexes.each do |i|
      case res
      when Array, YCP::Term
        if i.is_a? Fixnum
          if (0..res.size-1).include? i
            res = res[i]
          else
            YCP.y2warning "Index #{i} is out of array size"
            return default
          end
        else
          YCP.y2warning "Passed #{i.inspect} as index key for array."
          return default
        end
      when Hash
        if res.has_key? i
          res = res[i]
        else
          return default
        end
      else
        YCP.y2warning "Builtin index called on wrong type #{res.class}"
        return default
      end
    end
    return res
  end

  def self.add first, second
    return nil if first.nil? || second.nil?

    case first
    when Array
      if second.is_a? Array
        return first + second
      else
        return first.dup.push(second)
      end
    when Hash
      return first.merge second
    when String
      return first + second.to_s
    else
      return first + second
    end
  end

  def self.substract first, second
    return nil if first.nil? || second.nil?

    return first - second
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

  def self.comparable_object object
    return GenericComparable.new(object)
  end

  #speciality of this comparable is that it can compare various classes together like ycp, order is based on ycp class order
  class GenericComparable
    include Comparable
    
    def initialize value
      @value = value
    end
    #ordered classes from low priority to high
    # Only tricky part is Fixnum/Bignum, which is in fact same, so it has special handling in code
    CLASS_ORDER = [ NilClass, FalseClass, TrueClass, Fixnum, Bignum, Float, 
      String, YCP::Path, Symbol, Array, YCP::Term, Hash ]
    def <=> (second)
      if @value.class == second.class
        case @value
        when Array
          return ListComparator.new(@value) <=> second
        when NilClass
          return 0 #comparison of two nils is equality
        when Hash
          return HashComparator.new(@value) <=> second
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

  class ListComparator
    include Comparable
    def initialize value
      @value = value
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
        res = Ops.comparable_object(fval) <=> sval
        return res if res != 0
      end
      # no decision yet
      return @value.size <=> second.size
    end
  end

  class HashComparator
    include Comparable
    def initialize value
      @value = value
    end

    def <=>(second)
      comparator = Proc.new do |k1,k2|
        Ops.comparable_object(k1) <=> k2
      end
      keys = @value.keys.sort(&comparator)
      other_keys = second.keys.sort(&comparator)

      0.upto(keys.size-1) do |i|
        res = Ops.comparable_object(keys[i]) <=> other_keys[i]
        return res if res != 0

        res = Ops.comparable_object(@value[keys[i]]) <=> second[keys[i]]
        return res if res != 0
      end

      return @value.size <=> second.size
    end
  end
end
