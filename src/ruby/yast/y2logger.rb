# encoding: utf-8

require "logger"
require "singleton"

require "yast/logger"

module Yast

  # Stores the log group result data, used in {Y2Logger.group}.
  class LogGroupResult
    # @return [String,nil] result of the step as a textual description
    attr_accessor :summary

    # @return [Object ]result of the block
    attr_accessor :result

    # @param value [Boolean] set to true if the result of the group is a failure,
    #  overrides the state evaluated from the the {#result} attribute
    attr_writer :failed

    # these return values are considered failures by default,
    # can be overridden by setting the `failed` attribute
    FAILURES = [:abort, :cancel, false]

    # did the execution of the block failed?
    # @return [Boolean] true if the block failed
    def failed?
      if failed.nil?
        FAILURES.include?(result)
      else
        failed
      end
    end

  private

    # @return [Boolean,nil] explicit failure
    attr_reader :failed
  end

  # A Ruby Logger which wraps Yast.y2*() calls
  class Y2Logger < ::Logger
    include Singleton

    # location of the caller
    CALL_FRAME = 2

    def add(severity, _progname = nil, message = nil, &block)
      message = block.call if block

      case severity
      when DEBUG
        Yast.y2debug(CALL_FRAME, message)
      when INFO
        Yast.y2milestone(CALL_FRAME, message)
      when WARN
        Yast.y2warning(CALL_FRAME, message)
      when ERROR
        Yast.y2error(CALL_FRAME, message)
      when FATAL
        Yast.y2error(CALL_FRAME, message)
      when UNKNOWN
        Yast.y2internal(CALL_FRAME, message)
      else
        Yast.y2internal(CALL_FRAME, "Unknown error level #{severity}: Error: #{message}")
      end
    end

    def initialize(*_args)
      # do not write to any file, the actual logging is implemented in add()
      super(nil)
      # process also debug messages but might not be logged in the end
      self.level = ::Logger::DEBUG
    end

    # log a block of commands, adds a special begin and end markers into the log,
    # the block should be one big logical step in the process,
    # can be used recursively, e.g. log.group might call another log.group inside
    # @param description [String] short description of the block
    # @param block [Proc] block to call
    # @yieldparam group [LogGroupResult] can be optionally used to pass result details
    # @yieldreturn [Object] passed on;
    #   if one of `false`, `:abort`, `:cancel` ({LogGroupResult::FAILURES}),
    #   the group is logged as failed (log.error)
    # @return [Object] whatever the *block* returned
    def group(description, &block)
      details = LogGroupResult.new
      # mark start of the group
      info "::group::#{Process.clock_gettime(Process::CLOCK_MONOTONIC)}::#{description}"

      if block_given?
        ret = block.call(details)
      else
        raise ArgumentError, "Missing a block"
      end
      details.result = ret

      ret
    rescue StandardError => e
      # mark a failure
      details.failed = true
      details.summary = "Raised exception: #{e}"
      # reraise the original exception
      raise
    ensure
      # mark end of the group with result data, if it failed log as an error
      level = details.failed? ? :error : :info
      send(level, "::endgroup::#{Process.clock_gettime(Process::CLOCK_MONOTONIC)}::#{details.summary}")
    end
  end

  # This module provides access to Yast specific logging
  #
  # @example Yast::Logger example
  #    module Yast
  #      class Foo < Client
  #        include Yast::Logger
  #
  #        def foo
  #          # this will be logged into y2log using the usual y2log format
  #
  #          # Builtins.y2debug() replacement
  #          log.debug "debug"
  #
  #          # Builtins.y2milestone() replacement
  #          log.info "info"
  #
  #          # Builtins.y2error() replacement
  #          log.error "error"
  #
  #          # log a logical group of commands, useful for big tasks which
  #          # log too many details
  #          log.group("Adding repositories") do
  #            add_repositories
  #          end
  #
  #          # log a logical group of commands with result details
  #          log.group("Adding repositories") do |group|
  #            ret, repos = add_repositories
  #            if ret == :failed
  #              group.summary = "Could not add repositories"
  #              group.failed = true
  #            else
  #              group.summary = "Added #{repos.size} repositories"
  #            end
  #          end
  #        end
  #      end
  #    end
  #
  module Logger
    def log
      Y2Logger.instance
    end

    def self.included(base)
      base.extend self
    end
  end
end
