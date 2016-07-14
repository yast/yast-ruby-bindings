
require "yast"

module Yast
  class Profiler
    class << self
      include Yast::Logger

      RESULT_PATH = "/var/log/YaST2/profiler_result.txt".freeze

      # Start the Ruby Profiler. It start profilling. It also disables ruby VM
      # optimizations, so code execution will be slower.
      def start
        raise "multiple profiller start detected" if @started
        @original_compile_options = RubyVM::InstructionSequence.compile_option
        @started = true
        require "profiler"

        # turn on tracing and turn off specialized instruction which replace
        # some core ruby methods with its optimized variant to get complete
        # profiling. More info in book "Ruby Under a Microscope: Learning Ruby
        # Internals Through Experiment". Code is taken from ruby/lib/profile.rb
        RubyVM::InstructionSequence.compile_option = {
          trace_instruction:       true,
          specialized_instruction: false
        }

        at_exit { stop }
        Profiler__.start_profile
      end

      # Stops profiling
      # @param output [IO] an IO stream to print the profile to; if nil, uses a file at RESULT_PATH
      def stop(output = nil)
        return File.open(RESULT_PATH, "w") { |f| stop(f) } unless output

        Profiler__.print_profile(output)

        RubyVM::InstructionSequence.compile_option = @original_compile_options
        @started = false
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
        # sort the keys to have a deterministic behavior and to prefer Y2PROFILER
        # over the other variants, then do a case insensitive search
        key = ENV.keys.sort.find { |k| k.match(/\AY2PROFILER\z/i) }
        return false unless key

        "1" == ENV[key]
      end
    end
  end
end
