require 'ycp/builtins'

module YCP
  class Term
    # term symbol
    attr_reader :value
    # term parameters
    attr_reader :params

    def initialize value, *params
      @value = value
      @params = params
    end

    def == second
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
  end
end
