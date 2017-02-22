module Yast
  module Y2Base

    # Parses ARGV of y2base. it returns map with keys:
    #
    # - :generic_options [Hash]
    # - :client_name [String, nil]
    # - :client_options [Hash]
    # - :server_name [String, nil]
    # - :server_options [Array] ( of unparsed options as server parse it on its own)
    # @raise RuntimeError when unknown option appear or used wrongly
    def self.parse_arguments(args)
      ret = {}

      ret[:generic_options] = parse_generic_options(args)
      ret[:client_name] = args.shift
      ret[:client_options] = parse_client_options(args)
      ret[:server_name] = args.shift
      ret[:server_options] = args

      ret
    end

    def self.setup_signals
      Signal.trap("PIPE", "IGNORE")

      # SEGV, ILL and FPE is reserved, so cannot be set
      ["HUP", "INT", "QUIT", "ABRT", "TERM"].each do |name|
        Signal.trap(name) { signal_handler(name) }
      end
    end

    def self.signal_handler(name)
      puts "test"
      $stderr.puts "test"
      File.write("/tmp/signal", "handling signal #{name}")

      Signal.trap(name, "IGNORE")

      $stderr.puts "YaST got signal #{name}."

      signal_log_open do |f|
        f.puts "=== #{Time.now} ==="
        f.puts "YaST got signal #{name}."
        # TODO: print stored debug logs
        f.puts "Backtrace (only ruby one):"
        caller.each { |l| f.puts(l) }
      end

      system("/usr/lib/YaST2/bin/signal-postmortem")

      Signal.trap(name, "SYSTEM_DEFAULT")
      Process.kill(name, Process.pid)
    end

    LOG_LOCATIONS = ["/var/log/YaST2/signal", "y2signal.log"]
    private_class_method def self.signal_log_open(&block)
      index = 0
      begin
        path = LOG_LOCATIONS[index]
        return unless path
        File.open(path, "a") { |f| block.call(f) }
      rescue IOError, SystemCallError
        index +=1
        retry
      end
    end

    private_class_method def self.parse_generic_options(args)
      res = {}
      loop do
        return res unless option?(args.first)

        raise "Unknown option #{args.first}"
      end
    end

    private_class_method def self.parse_client_options(args)
      res = {}
      string_param = false
      res[:params] = []
      loop do
        return res unless option?(args.first)

        arg = args.shift
        case arg
        when "-S"
          string_param = true
        when /^\(/
          raise "Only string client parameters supported" unless string_param

          res[:params] << arg[1..-2]
        else
          raise "Unknown option #{arg}"
        end
      end
    end

    private_class_method def self.option?(arg)
      return false unless arg
      return true if arg[0] == "-"
      return true if arg[0] == "(" && arg[-1] == ")"

      return false
    end
  end
end
