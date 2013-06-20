require "ostruct"

require "yast/yast"

module Yast
  module Exportable

    class ExportData < OpenStruct
      def private?
        table = marshal_dump
        return !!table[:private]
      end
    end

    def published_functions
      @__published_functions ||= {}
    end

    def published_variables
      @__published_variables ||= {}
    end

    def publish options
      raise "Missing signature" unless options[:type]
      # convert type to full specification
      type = options[:type].delete " \t"
      type = type.gsub(/map([^<]|$)/,'map<any,any>\\1')
      type = type.gsub(/list([^<]|$)/,'list<any>\\1')
      options[:type] = type
      if options[:function]
        published_functions[options[:function]] = ExportData.new options
      elsif options[:variable]
        published_variables[options[:variable]] = ExportData.new options
        if !options[:private] || ENV["Y2ALLGLOBAL"]
          attr_writer :"#{options[:variable]}"
          # reader that do deep copy
          class_eval "def #{options[:variable]}; Yast.deep_copy(@#{options[:variable]}); end"
        end
      else
        raise "Missing publish kind"
      end
    end

    module ExceptionReporter
      def last_exception
        @__last_exception
      end
    end
    def self.extended(mod)
      mod.send(:include,ExceptionReporter)
    end
  end
end
