module Yast
  class Break < StandardError
    def initialize(msg="Yast Break in a block")
      super(msg)
    end
  end
end
