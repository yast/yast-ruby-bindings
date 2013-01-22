require "ostruct"

module YCP
  module Exportable

    def published_methods
      self.class.published_methods
    end

    def published_variables
      self.class.published_variables
    end

    module ClassMethods
      class ExportData < OpenStruct; end

      def published_methods
        @__published_methods ||= {}
      end

      def published_variables
        @__published_variables ||= {}
      end

      def publish options
        raise "Missing signature" unless options[:type]
        if options[:method]
          published_methods[options[:method]] = ExportData.new options
        elsif options[:variable]
          published_variables[options[:variable]] = ExportData.new options
          self.class.module_eval "attr_accessor :'#{options[:variable]}'"
        else
          raise "Missing publish kind"
        end
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end
  end
end
