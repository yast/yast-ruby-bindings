module Yast
  module CyclicYinInclude
    def initialize_cyclic_yin(include_target)
      Yast.include include_target, "cyclic_yang.rb"
    end

    def yin
      "YIN"
    end
  end
end
