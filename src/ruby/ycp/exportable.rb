require "ostruct"

module YCP
  module Exportable
    def published_functions
      @__published_functions ||= {}
    end

    def published_variables
      @__published_variables ||= {}
    end

    def publish options
      raise "Missing signature" unless options[:type]
      if options[:function]
        published_functions[options[:function]] = OpenStruct.new options
      elsif options[:variable]
        published_variables[options[:variable]] = OpenStruct.new options
        attr_accessor :"#{options[:variable]}"
      else
        raise "Missing publish kind"
      end
    end
  end
end
