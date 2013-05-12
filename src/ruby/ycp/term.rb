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

    def [] index
      params[index]
    end

    def []= index, value
      params[index] = value
    end

    def size
      params.size
    end

    def dup
      YCP::Term.new value, *params.dup
    end

    def to_s
      if params.empty?
        "`#{value} ()"
      else
        "`#{value} (#{params.map{|p| YCP::Builtins.inside_tostring p}.join ', '})"
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
