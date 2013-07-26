module Yast
  # represent type YCPExternal for binary payload without operations.
  # Used for example to pass object from perl.
  class External
    # String identifier of payload
    attr_reader :magic

    # creates external with given payload, binary data must be assigned from C.
    # Constructed only by bindings when given from component system.
    def initialize (magic)
      @magic = magic
    end

    def to_s
      "External payload #{magic}"
    end
  end
end
