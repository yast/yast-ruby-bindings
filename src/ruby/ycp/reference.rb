module YCP
  class Reference
    attr_reader :object, :signature

    def initialize object, signature
      @object = object
      @signature = signature
    end

    def call *args
      @object.call *args
    end
  end
end
