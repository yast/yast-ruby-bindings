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
    
  end
end
