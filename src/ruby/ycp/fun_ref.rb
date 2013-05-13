module YCP
  class FunRef
    attr_reader :signature, :remote_method

    def initialize met, signature
      @remote_method = met
      raise "invalid argument #{met.inspect}" unless met.respond_to? :call

      # expand signature to containt full spec of lists and maps
      signature = signature.gsub(/map(\s*([^<\s]|$))/,"map<any,any>\\1")
      signature = signature.gsub(/list(\s*([^<\s]|$))/,"list<any>\\1")
      @signature = signature
    end

    def call *args
      @remote_method.call *args
    end
  end
end
