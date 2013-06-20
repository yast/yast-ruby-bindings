module Yast
  class External
    attr_reader :magic

    def initialize (magic)
      @magic = magic
    end

    def to_s
      "External payload #{magic}"
    end
  end
end
