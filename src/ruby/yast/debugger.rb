# typed: ignore

require "yast"

module Yast
  class Debugger
    class << self
      include Yast::Logger
      include Yast::UIShortcuts

      # Start the Ruby debugger. It handles the current UI mode and displays
      # an user request if the debugger front-end needs to be started manually.
      # @param [Boolean] remote if set to true the server is accesible from network.
      #   By default the debugger can connect only from the local machine, not from
      #   the network. If you need remote debugging then enable it.
      #   WARNING: There is no authentication, everybody can connect to
      #   the debugger! Use only in a trusted network as this is actually
      #   a backdoor to the system! For secure connection use SSH and start
      #   the debugger locally after connecting via SSH.
      # @param [Integer] port the port number where the debugger server will
      #   listen to
      # @param [Boolean] start_client autostart the debugger client
      #   (ignored in remote debugging)
      # @example Start the debugger with default settings:
      #   require "yast/debugger"
      #   Yast::Debugger.start
      # @example When using the debugger temporary you can use just simple:
      #   require "byebug"
      #   byebug
      def start(remote: false, port: 3344, start_client: true)
        return unless load_debugger

        # do not start the server if it is already running
        if Byebug.started?
          log.warn "The debugger is already running at port #{Byebug.actual_port}"
          log.warn "Skipping the server setup"
        else
          Yast.import "UI"
          if UI.TextMode || remote || !start_client
            # in textmode or in remote mode ask the user to start
            # the debugger client manually
            UI.OpenDialog(Label(debugger_message(remote, port)))
            popup = true
          else
            # in GUI open an xterm session with the debugger
            start_gui_session(port)
          end

          # start the server and wait for connection, add an extra delay
          # if we start the front end automatically to get the server ready
          # (to avoid "Broken pipe" error)
          # FIXME: looks like a race condition inside byebug itself...
          start_server(remote, port, delay: !popup)

          UI.CloseDialog if popup
        end

        # start the debugger session
        byebug
        # Now you can inspect the current state in the debugger,
        # or use "next" to continue.
        # Use "help" command to see the available commands, see more at
        # https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md
      end

      # start the Ruby debugger if "Y2DEBUGGER" environment
      # variable is set to "1", "remote" or "manual" (the test is case
      # insensitive, "y2debugger" variable can be also used)
      def start_from_env
        # do not evaluate the debugger request again for each client started,
        # run the debugger evaluation only once
        return if @debugger_handled
        @debugger_handled = true

        debug = env_value
        return if debug != "1" && debug != "remote" && debug != "manual"

        # FIXME: the UI.TextMode call is used here just to force the UI
        # initialization, if it is initialized inside the start method the
        # ncurses UI segfaults :-(
        # interestengly, the Qt UI works correctly...
        Yast.import "UI"
        log.info "text mode: #{UI.TextMode}"

        log.info "Debugger set to: #{debug}"
        start(remote: debug == "remote", start_client: debug != "manual")
      end

      # is the Ruby debugger installed and can be loaded?
      # @return [Boolean] true if the debugger is present
      def installed?
        require "byebug"
        true
      rescue LoadError
        false
      end

    private

      # read the debugger value from Y2DEBUGGER environment variable,
      # do case insensitive match
      # @return [String,nil] environment value or nil if not defined
      def env_value
        # sort the keys to have a deterministic behavior and to prefer Y2DEBUGGER
        # over the other variants, then do a case insensitive search
        key = ENV.keys.sort.find { |k| k.match(/\AY2DEBUGGER\z/i) }
        log.debug "Found debugger key: #{key.inspect}"
        key ? ENV[key] : nil
      end

      # load the Ruby debugger, report an error on failure
      # @return [Boolean] true if the debugger was loaded successfuly,
      #   false on error
      def load_debugger
        require "byebug"
        require "byebug/core"
        true
      rescue LoadError
        # catch loading error, the debugger is optional (might not be present)
        Yast.import "Report"
        Report.Error(format("Cannot load the Ruby debugger.\n" \
          "Make sure '%s' Ruby gem is installed.", "byebug"))
        false
      end

      # starts the debugger server and waits for a client connection
      # @param [Boolean] remote if set to true the server is accesible from network
      # @param [Integer] port the port number used by the server
      # @param [Boolean] delay add extra delay after starting the server
      def start_server(remote, port, delay: false)
        Byebug.wait_connection = true
        host = remote ? "0.0.0.0" : "localhost"
        log.info "Starting debugger server (#{host}:#{port}), waiting for connection..."
        Byebug.start_server(host, port)
        # extra delay if needed
        sleep(3) if delay
      end

      # starts a debugger session in xterm
      # @param [Integer] port the port number to connect to
      def start_gui_session(port)
        job = fork do
          # wait until the main thread starts the debugger and opens the port
          # for listening
          loop do
            break if port_open?(port)
            sleep(1)
          end

          # start the debugger client in an xterm session
          exec "xterm", "-e", "byebug", "-R", port.to_s
        end

        # detach the process, we do not wait for it so avoid zombies
        Process.detach(job)
      end

      # compose the popup message describing how to manually connect to
      # the running debugger
      # @param [Boolean] remote boolean flag indicating whether the debugger
      #   can be accessed remotely
      # @param [Integer] port the port number used by the debugger
      # @return [String] text
      def debugger_message(remote, port)
        if remote
          # get the local IP addresses
          require "socket"
          remote_ips = Socket.ip_address_list.select { |a| a.ipv4? && !a.ipv4_loopback? }
          cmd = remote_ips.map { |a| debugger_cmd(a.ip_address, port) }.join("\n")

          prefix = if remote_ips.size > 1
            "To connect to the debugger from a remote machine use one of these commands:"
          else
            "To connect to the debugger from a remote machine use this command:"
          end
        else
          prefix = "To start the debugger switch to another console and run:"
          cmd = debugger_cmd(nil, port)
        end

        "#{prefix}\n\n#{cmd}\n\nWaiting for the connection..."
      end

      # construct a debugger command displayed to user in a popup
      # @param [String,nil] host the machine host name or IP address, nil if
      #   the debugger can be accessed only locally
      # @param [Integer] port the port number used by the debugger
      # @return [String] byebug command label
      def debugger_cmd(host, port)
        host_param = host ? "#{host}:" : ""
        "    byebug -R #{host_param}#{port}"
      end

      # is the target port open?
      # @param [Integer] port the port number
      # @return [Boolean] true if the port is open, false otherwise
      def port_open?(port)
        require "socket"

        begin
          TCPSocket.new("localhost", port).close
          true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          false
        end
      end
    end
  end
end
