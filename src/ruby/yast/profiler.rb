
require "yast"

module Yast
  class Profiler
    class << self
      include Yast::Logger

      RESULT_PATH = "/tmp/yast_profile.txt"

      # Start the Ruby Profiler. It start profilling. It also disables ruby VM
      # optimizations, so code execution will be slower.
      def start
        raise "multiple profiller start detected" if @started
        @original_compile_options = RubyVM::InstructionSequence.compile_option
        @started = true
        require "profiler"

        # turn on tracing and turn of specialized instruction to get complete profilling
        RubyVM::InstructionSequence.compile_option = {
          trace_instruction:       true,
          specialized_instruction: false
        }

        at_exit { File.open(RESULT_PATH, "w") { |f| Profiler__.print_profile(f) } }
        Profiler__.start_profile
      end

      # start the Ruby profiler if "Y2PROFILER" environment
      # variable is set to "1" or "true"(the test is case
      # insensitive, "y2profiler" variable can be also used)
      def start_from_env
        # do not evaluate again for each client started, run the evaluation only once
        return if @profiler_handled
        @profiler_handled = true

        return unless env_value

        log.info "profiler enabled"
        start
      end

    private

      # read the Y2PROFILER environment variable,
      # do case insensitive match
      # @return [Boolean] true if enabled
      def env_value
        # sort the keys to have a deterministic behavior and to prefer Y2DEBUGGER
        # over the other variants, then do a case insensitive search
        key = ENV.keys.sort.find { |k| k.match(/\AY2PROFILER\z/i) }
        return false unless key

        ["1", "true"].include?(ENV[key])
      end
    end
  end
end
