require "ostruct"

module Yast
  # Provides ability to export functions and variables to Yast component system.
  # The most important method is {Yast::Exportable#publish}
  module Exportable
    # Holder for exported data
    class ExportData < OpenStruct
      # Is exported data only for private purpose.
      # It is useful only to test private methods from old Yast testsuite.
      def private?
        table = marshal_dump
        !!table[:private]
      end
    end

    # list of published functions
    def published_functions
      @__published_functions ||= {}
    end

    # list of published variables
    def published_variables
      @__published_variables ||= {}
    end

    # Publishes function or variable to component system
    # @param (Hash) options specified parameters
    # @option options [String] :type specified Yast type that allows communication with type languages
    # @option options [TrueClass,FalseClass] :private (false) id specified then exported only in old testsuite environment
    #   after convert of testsuite all private publish call can be removed
    # @option options [Symbol] :variable exported variable
    # @option options [Symbol] :function exported function
    # @note mandatory options are :type and :variable xor :function. Both together is not supported
    def publish(options)
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
          attr_accessor :"#{options[:variable]}"
        end
      else
        raise "Missing publish kind"
      end
    end

    # Module that extends class to allow reporting last exception to component system
    module ExceptionReporter
      # Reader for last exception
      def last_exception
        @__last_exception
      end
    end

    # Extend by {ExceptionReporter} to allow exported module report last exception
    def self.extended(mod)
      mod.send(:include,ExceptionReporter)
    end
  end
end
