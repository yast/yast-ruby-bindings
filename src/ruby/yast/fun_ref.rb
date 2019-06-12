# typed: true
module Yast
  # Provides wrapper to pass reference to function.
  # It is used by component system to allow passing reference to function.
  # Class is immutable
  #
  # @example pass function as reference
  #   def a
  #     return 5
  #   end
  #
  #   ref_a = FunRef.new method(:a), "integer()"
  #
  # @example pass reference to lambda
  #   ref_lambda = FunRef.new lambda{ return 5 }, "integer()"
  class FunRef
    # Signature recognized by YCPType
    attr_reader :signature
    # reference to method responds to method call
    attr_reader :remote_method

    def initialize(met, signature)
      @remote_method = met
      raise "invalid argument #{met.inspect}" unless met.respond_to? :call

      # expand signature to containt full spec of lists and maps
      signature = signature.gsub(/map(\s*([^<\s]|$))/, "map<any,any>\\1")
      signature = signature.gsub(/list(\s*([^<\s]|$))/, "list<any>\\1")
      @signature = signature
    end

    # Forwards call to reference method
    def call(*args)
      @remote_method.call(*args)
    end
  end
end
