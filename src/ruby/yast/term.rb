require 'yast/yast'
require 'yast/builtins'
require 'yast/ops'

module Yast
  # Represents YCP type term
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

    # gets number of parameters
    def size
      params.size
    end

    def clone
      Yast::Term.new value, *Yast.deep_copy(params)
    end

    def to_s
      "`#{value} (#{params.map{|p| Yast::Builtins.inside_tostring p}.join ', '})"
    end

    def <=> (other)
      res = value <=> other.value
      return res if res != 0

      list = Ops.comparable_object(params)
      return list <=> other.params
    end
  end
end
