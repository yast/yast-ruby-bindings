module Yast
  module Y2StartHelpers
    # Configure global environment for YaST
    #
    # Currently it only sets values for $PATH and $GODEBUG.
    #
    # By configuring $PATH, it ensures that correct external programs are executed when
    # relative paths are given, so possible CVEs are avoided when running YaST.
    #
    # $GODEBUG is configured to enable CN (Common Name) matching in SSL certificates
    # used by Go programs (suseconnect-ng used by registration)
    #
    # Note that forked processes will inherit the environment configuration, for example
    # when executing commands via SCR or Cheetah.
    def self.config_env
      ENV["PATH"] = "/sbin:/usr/sbin:/usr/bin:/bin"

      # Note: this setting was removed in go-1.17 (https://go.dev/doc/go1.17),
      # SLE15 uses go-1.16
      if ENV["GODEBUG"]
        # check if already enabled
        if !ENV["GODEBUG"].include?("x509ignoreCN=0")
          # append to existing settings
          ENV["GODEBUG"] = "#{ENV["GODEBUG"]},x509ignoreCN=0"
        end
      else
        ENV["GODEBUG"] = "x509ignoreCN=0"
      end
    end

    # Parses ARGV of y2start. it returns map with keys:
    #
    # - :generic_options [Hash]
    # - :client_name [String]
    # - :client_options [Hash] always contains `params:` with Array of client arguments
    # - :server_name [String]
    # - :server_options [Array] ( of unparsed options as server parse it on its own)
    # @raise RuntimeError when unknown option appear or used wrongly
    def self.parse_arguments(args)
      ret = {}

      ret[:generic_options] = parse_generic_options(args)
      # for --help early quit as other argument are ignored
      return ret if ret[:generic_options][:help]
      ret[:client_name] = args.shift or raise "Missing client name."
      ret[:client_options] = parse_client_options(args)
      ret[:server_name] = args.shift or raise "Missing server name."
      ret[:server_options] = args

      ret
    end

    def self.help
      "Usage: y2start [GenericOpts] Client [ClientOpts] Server " \
      "[Specific ServerOpts]\n" \
      "\n" \
      "GenericOptions are:\n" \
      "    -h --help         : Sprint this help\n" \
      "\n" \
      "ClientOptions are:\n" \
      "    -a --arg          : add argument for client. Can be used multiple times.\n" \
      "\n" \
      "Specific ServerOptions are any options passed on unevaluated.\n" \
      "\n" \
      "Examples:\n" \
      "y2start installation qt\n" \
      "    Start binary y2start with intallation.ycp as client and qt as server\n" \
      "y2start installation -a initial qt\n" \
      "    Provide parameter initial for client installation\n" \
      "y2start installation qt -geometry 800x600\n" \
      "    Provide geometry information as specific server options\n"
    end

    # so how works signals in ruby version?
    # It logs what we know about signal and then continue with standard ruby
    # handler, which raises {SignalException} that can be processed. If it is
    # not catched, it show popup asking for report bug.
    def self.setup_signals
      Signal.trap("PIPE", "IGNORE")

      # SEGV, ILL and FPE is reserved, so cannot be set
      ["HUP", "INT", "QUIT", "ABRT", "TERM"].each do |name|
        Signal.trap(name) { signal_handler(name) }
      end
    end

    # Returns application title string
    def self.application_title(client_name)
      # do not fail if gethostname failed
      hostname = Socket.gethostname rescue ""
      hostname = "" if hostname == "(none)"
      hostname = " @ #{hostname}" unless hostname.empty?
      if is_s390
        # e.g. stdout "2964 = z13 IBM z13" transfered into "IBM z13"
        arch_array = read_values.split("=")
        arch_array.shift if arch_array.size > 1
        architecture = arch_array.join(' ').strip
        arch_array = architecture.split(' ')
        arch_array.shift if arch_array.size > 1
        architecture = arch_array.join(' ')

        if !Yast::UI.TextMode
          # Show the S390 architecutue in the QT banner only.
          # The environment variable YAST_BANNER will be read and shown
          # in libyui-qt.
          ENV["YAST_BANNER"] = architecture
          architecture = ""
        end
      else
        architecture = ""
      end
      left_title = "YaST2 - #{client_name}#{hostname}"
      left_title + architecture.rjust(78-left_title.size)
    end


    # client returned special result, this is used as offset (or as generic error)
    RES_CLIENT_RESULT = 16
    # yast succeed
    RES_OK = 0
    # Symbols representing failure
    FAILED_SYMBOLS = [:abort, :cancel]
    # transform various ruby objects to exit code. Useful to detection if YaST process failed
    # and in CLI
    def self.generate_exit_code(value)
      case value
      when nil, true
        RES_OK
      when false
        RES_CLIENT_RESULT
      when Integer
        RES_CLIENT_RESULT + value
      when Symbol
        FAILED_SYMBOLS.include?(value) ? RES_CLIENT_RESULT : RES_OK
      else
        RES_OK
      end
    end

    private_class_method def self.read_values
      arch = `/usr/bin/read_values -c`.strip
      return "" unless $?.success?
      arch
    end 

    private_class_method def self.is_s390
      arch = `/usr/bin/arch`.strip
      return false unless $?.success?
      arch.start_with?("s390")
    end

    private_class_method def self.signal_handler(name)
      Signal.trap(name, "IGNORE")

      # Exception swallowing: writing to stderr could fail if the parent process was killed,
      # see bsc#1154854. Note that $stderr.closed? returns false.
      begin
        $stderr.puts "YaST got signal #{name}."
      rescue Errno::EIO
        # Nothing to do
      end

      signal_log_open do |f|
        f.puts "=== #{Time.now} ==="
        f.puts "YaST got signal #{name}."
        # TODO: print stored debug logs
        f.puts "Backtrace (only ruby one):"
        caller.each { |l| f.puts(l) }
      end

      system("/usr/lib/YaST2/bin/signal-postmortem")

      Signal.trap(name, "DEFAULT")
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


        arg = args.shift
        case arg
        when "-h", "--help"
          res[:help] = true
        else
          raise "Unknown option #{args.first}"
        end
      end
    end

    private_class_method def self.parse_client_options(args)
      res = {}
      res[:params] = []
      loop do
        return res unless option?(args.first)

        arg = args.shift
        case arg
        when "-a", "--arg"
          param = args.shift
          raise "Missing argument for --arg" unless param

          res[:params] << param
        else
          raise "Unknown option #{arg}"
        end
      end
    end

    private_class_method def self.option?(arg)
      return false unless arg
      return true if arg[0] == "-"

      return false
    end
  end
end
