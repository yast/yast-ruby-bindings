module Yast
  module CyclicYangInclude
    def initialize_cyclic_yang(include_target)
      Yast.include include_target, "cyclic_yin.rb"
    end

    def yang
      "YANG"
    end
  end
end
