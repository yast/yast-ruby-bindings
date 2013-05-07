module YCP
  class External
    attr_reader :magic

    def initialize (magic)
      @magic = magic
    end
  end
end
