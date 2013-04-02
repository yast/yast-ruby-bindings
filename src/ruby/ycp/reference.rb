module YCP
  class Reference
    attr_reader :signature

    def initialize met, signature
      @remote_method = met
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
