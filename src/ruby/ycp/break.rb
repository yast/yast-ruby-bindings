module YCP
  class Break < StandardError
    def initialize(msg="YCP Break in a block")
      super(msg)
    end
  end
end
