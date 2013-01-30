require 'ycp/builtins'
require 'ycp/ops'

module YCP
  class Term
    include Comparable

    # term symbol
    attr_reader :value
    # term parameters
    attr_reader :params

    def initialize value, *params
      @value = value
      @params = params
    end

    def == second
      return false if second.nil?
      value == second.value && params == second.params
    end

    def != second
      !(self == second)
    end

    def [] index
      params[index]
    end

    def size
      params.size
    end

    def to_s
      if params.empty?
        "`#{value} ()"
      else
        "`#{value} (#{params.map{|p| YCP::Builtins.tostring p}.join ', '})"
      end
    end

    def <=> (other)
      res = value <=> other.value
      return res if res != 0

      list = Ops.comparable_object(params)
      return list <=> other.params
    end
  end
end
