module Yast
  # Class that simulates ycp break behavior.
  #
  # @deprecated Go out of block with standard ruby methods
  class Break < StandardError
    def initialize(msg = "Yast Break in a block")
      super(msg)
    end
  end
end
