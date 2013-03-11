module YCP
  class Reference
    attr_reader :signature

    def initialize met, signature
      @remote_method = met
      @signature = signature
    end

    def call *args
      @remote_method.call *args
    end
  end
end
