require "ostruct"

module YCP
  module Exportable
    def published_methods
      @__published_methods ||= {}
    end

    def published_variables
      @__published_variables ||= {}
    end

    def publish options
      raise "Missing signature" unless options[:type]
      if options[:method]
        options[:method_name] = options[:method].to_s #tricky part to not be overcloaked by internal method
        published_methods[options[:method]] = OpenStruct.new options
      elsif options[:variable]
        published_variables[options[:variable]] = OpenStruct.new options
        attr_accessor :"#{options[:variable]}"
      else
        raise "Missing publish kind"
      end
    end
  end
end
