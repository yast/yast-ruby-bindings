module Ops
  def self.equal first, second
    return first == second
  end

  def self.not_equal first, second
    return !equal(first, second)
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
    # we have guarantie that we get same types 
    # so we create object that can compare same type
    case object
    when TrueClass, FalseClass
      return BooleanComparator.new object
    when NilClass
      return NilComparable.new
    when Array
      return ListComparator.new object
    when Hash
      #hash is really bogus piece, as it compare on quite undefined key hash value
      raise "Not yet supported"
    else
      return object
    end
  end

  class NilComparable
    def <=>(second)
      return 0 if second.nil?
      return -1
    end
  end

  class BooleanComparator
    include Comparable
    def initialize value
      @value = value
    end

    def <=>(second)
      if @value == second
        return 0
      end

      #rule is that true always rules over false
      return @value ? 1 : -1
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

end
