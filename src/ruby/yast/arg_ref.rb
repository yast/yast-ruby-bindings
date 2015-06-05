module Yast
  # Provides wrapper to pass by reference any value, even immutable like Fixnum or Symbol.
  # It is used by component system to allow passing by reference.
  #
  # @example pass value as reference
  #   #Component function void T::test(integer &)
  #   a = 6
  #   ref_a = ArgRef.new a
  #   T.test(ref_a)
  #   a = ref_a.value

  class ArgRef
    attr_accessor :value

    def initialize(initial = nil)
      @value = initial
    end
  end
end
