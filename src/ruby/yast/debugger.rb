
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
      # @param [Fixnum] port the port number where the debugger server will
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
        begin
          require "byebug"
          require "byebug/core"
        rescue LoadError
          # catch loading error, the debugger is optional (might not be present)
          Yast.import "Report"
          Report.Error(format("Cannot load the Ruby debugger.\n" \
            "Make sure '%s' Ruby gem is installed.") % "byebug")
          return
        end

        popup = false

        # do not start the server if it is already running
        if Byebug.started?
          log.warn "The debugger is already running at port #{Byebug.actual_port}"
          log.warn "Skipping the server setup"
        else
          Yast.import "UI"
          wait = false
          if UI.TextMode || remote || !start_client
            # in textmode or in remote mode ask the user to start
            # the debugger client manually
            UI.OpenDialog(Label(debugger_message(remote, port)))
            popup = true
          else
            # in GUI open an xterm session with the debugger
            start_gui_session(port)
            # wait a bit to get the server ready (to avoid "Broken pipe" error)
            # FIXME: looks like a race condition inside byebug itself...
            wait = true
          end

          # start the server and wait for connection
          start_server(remote, port, wait)

          UI.CloseDialog if popup
        end

        # start the debugger session
        byebug
        # Now you can inspect the current state in the debugger,
        # or use "next" to continue.
        # Use "help" command to see the available commands, see more at
        # https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md
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

      # starts the debugger server and waits for a cleint connection
      # @param [Boolean] remote if set to true the server is accesible from network
      # @param [Fixnum] port the port number used by the server
      def start_server(remote, port, wait)
        Byebug.wait_connection = true
        host = remote ? "0.0.0.0" : "localhost"
        log.info "Starting debugger server (#{host}:#{port}), waiting for connection..."
        Byebug.start_server(host, port)
        sleep(3) if wait
      end

      # starts a debugger session in xterm
      # @param [Fixnum] port the port number to connect to
      def start_gui_session(port)
        job = fork do
          # wait until the main thread starts the debugger and opens the port
          # for listening
          loop do
            break if port_open?(port)
            sleep(1)
          end

          # start the debugger client in an xterm session
          exec "xterm", "-e", "byebug", "-R", "#{port}"
        end

        # detach the process, we do not wait for it so avoid zombies
        Process.detach(job)
      end

      # compose the popup message describing how to manually connect to
      # the running debugger
      # @return [String] text
      def debugger_message(remote, port)
        waiting = "Waiting for the connection..."
        if remote
          # get the local IP addresses
          require "socket"
          remote_ips = Socket.ip_address_list.select { |a| a.ipv4? && !a.ipv4_loopback? }
          cmds = remote_ips.map { |a| debugger_cmd(a.ip_address, port) }.join("\n")

          "To connect to the debugger from a remote machine use this command:" \
            "\n\n#{cmds}\n\n#{waiting}"
        else
          "To start the debugger switch to another console and run\n\n" \
            "#{debugger_cmd(nil, port)}\n\n#{waiting}"
        end
      end

      def debugger_cmd(host, port)
        host_param = host ? "#{host}:" : ""
        "    byebug -R #{host_param}#{port}"
      end

      # is the target port open?
      # @param [Fixnum] port the port number
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
