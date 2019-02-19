
require "singleton"
require "yast/logger"

module Yast
  # A wrapper for Ruby Tracer
  class Y2Tracer
    include Singleton
    include Yast::Logger

    def initialize
      @stack_level = 0
    end

    def enable
      tracer.enable
    end

    def disable
      # creating the Tracer and then disabling it is pointless...
      return unless @tracer
      tracer.disable
    end

    def tracer
      @tracer ||= TracePoint.trace(:line, :raise, :call, :return, :c_call, :c_return) do |tp|
        @tracer.disable if @tracer
        case tp.event
        when :call, :c_call
          if silent_tracing(tp.defined_class, tp.method_id)
            @stack_level += 1
          end
          log.info "TRACER: Calling method #{tp.defined_class}.#{tp.method_id}" if @stack_level.zero?
        when :line
          log.info "TRACER: Executing line #{tp.path}:#{tp.lineno}" if @stack_level.zero?
        when :raise
          log.info "TRACER: Raised exception #{tp.raised_exception.inspect}" if @stack_level.zero?
        when :return, :c_return
          log.info "TRACER: Method #{tp.defined_class}.#{tp.method_id} returned: #{tp.return_value.inspect}." if @stack_level.zero?
          if silent_tracing(tp.defined_class, tp.method_id)
            @stack_level -= 1
          end
        when :b_return
          log.info "TRACER: Block returned returned: #{tp.return_value.inspect}." if @stack_level.zero?
        end
        @tracer.enable if @tracer
      end
    end

  private

    def silent_tracing(klass, method)
      # ignore some YaST calls so the log does not explode
      klass == Yast::Logger || klass == ::Logger || (klass == Yast && method == :deep_copy)
    end
  end
end
