require "yast/builtinx"
require "yast/builtins"
require "yast/ops"
require "yast/debugger"
require "yast/profiler"
require "yast/yast"

# @private we need it as clients is called in global contenxt
GLOBAL_WFM_CONTEXT = proc {}
module Yast
  # Wrapper class for WFM component in Yast
  # See yast documentation for WFM
  module WFM
    extend Yast::Logger

    # Returns list of arguments passed to client or element at given index
    #
    # @example Get all args
    #    Yast::WFM.Args
    #
    # @example Get only first argument
    #    Yast::WFM.Args 0
    def self.Args(*args)
      call_builtin_wrapper("Args", *args)
    end

    # Checks if client of given name exists on system
    #
    # @note useful for checking before calling given client
    # @see Yast::WFM.CallFunction
    # @return [true,false]
    #
    # @example Check if there is client "inst_bootloader"
    #    Yast::WFM.ClientExists "inst_bootloader"
    def self.ClientExists(client)
      call_builtin_wrapper("ClientExists", client)
    end

    # Runs execute on local system agent operating on inst-sys
    #
    # @param path[Yast::Path, String] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Execute common agent execute
    #
    # @example Run command in bash in inst-sys
    #    Yast::WFM.Execute(Yast::Path.new(".local.bash"), "halt -p")
    def self.Execute(path, *args)
      call_builtin_wrapper("Execute", Yast.path(path), *args)
    end

    # Returns current encoding code as string
    #
    # @deprecated enconding is now always UTF-8
    # @return [String]
    def self.GetEncoding
      call_builtin_wrapper("GetEncoding")
    end

    # Returns enconding of environment where Yast start
    #
    # @return [String]
    def self.GetEnvironmentEncoding
      call_builtin_wrapper("GetEnvironmentEncoding")
    end

    # Returns current language without modifiers as string
    #
    # @return [String]
    # @example return value
    #   Yast::WFM.GetLanguage
    #     => "en_US.UTF-8"
    def self.GetLanguage
      call_builtin_wrapper("GetLanguage")
    end

    # Runs read on local system agent operating on inst-sys
    #
    # @param path[Yast::Path, String] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Read common agent read
    #
    # @example Read kernel cmdline
    #    Yast::WFM.Read(path(".local.string"), "/proc/cmdline")
    def self.Read(path, *args)
      call_builtin_wrapper("Read", Yast.path(path), *args)
    end

    # Closes SCR handle obtained via {SCROpen}
    #
    # If SCR is set as default, then try to switch to another reasonable SCR
    # openned
    def self.SCRClose(handle)
      call_builtin_wrapper("SCRClose", handle)
    end

    # Gets handle of current default SCR
    def self.SCRGetDefault
      call_builtin_wrapper("SCRGetDefault")
    end

    # Gets name of SCR associated with handle
    #
    # @return [String]
    def self.SCRGetName(handle)
      call_builtin_wrapper("SCRGetName", handle)
    end

    # Tests if scr instance is pointed to chroot
    # @return [Boolean]
    def self.scr_chrooted?
      SCRGetName(SCRGetDefault()) != "scr"
    end

    # Returns root on which scr operates.
    # @return [String] path e.g. "/" when scr not switched
    # or "/mnt" when installation was switched.
    def self.scr_root
      case SCRGetName(SCRGetDefault())
      when "scr"
        "/"
      when /chroot=(.*):scr/
        Regexp.last_match(1)
      else
        raise "invalid SCR instance #{SCRGetName(SCRGetDefault())}"
      end
    end

    # Creates new SCR instance
    #
    # It is useful for installation where agents start operation on installed system
    #
    # @param name[String] name for instance. Currently it is supported on scr name
    #    with possible chrooting in format `"chroot=<path_to_chroot>:scr"`
    # @param check_version[Boolean] check if chrooted version match current
    #    core version
    # @return handle of SCR instance
    #
    # @example open SCR instance on /mnt root without version check
    #    Yast::WFM.SCROpen("chroot=/mnt:scr", false)
    def self.SCROpen(name, check_version)
      call_builtin_wrapper("SCROpen", name, check_version)
    end

    # Sets the default SCR to given handle
    def self.SCRSetDefault(handle)
      call_builtin_wrapper("SCRSetDefault", handle)
    end

    # Sets language for translate with optional enconding
    def self.SetLanguage(language, *args)
      call_builtin_wrapper("SetLanguage", language, *args)
    end

    # Runs write on local system agent operating on inst-sys
    #
    # @param path[Yast::Path, String] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Read common agent execute
    #
    # @example Write yast inf file in inst-sys
    #    Yast::WFM.Write(path(".local.string"), "/etc/yast.inf", yast_inf)
    def self.Write(path, *args)
      call_builtin_wrapper("Write", Yast.path(path), *args)
    end

    # calls client of given name with passed args
    #
    # @param client[String] name of client to run without suffix
    # @param args[Array] additional args passed to client, that can be obtained with
    #   {WFM.Args}
    # @return response from client
    #
    # @example call inst_moust client living in $Y2DIR/clients/inst_mouse.rb with parameter true
    #     Yast::WFM.CallFunction("inst_mouse", [true])
    def self.CallFunction(client, args = [])
      if !client.is_a?(::String)
        raise ArgumentError, "CallFunction first parameter('#{client.inspect}') have to be String."
      end
      if !args.is_a?(::Array)
        raise ArgumentError, "CallFunction second parameter('#{args.inspect}') have to be Array."
      end

      call_builtin_wrapper("CallFunction", client, args)
    end

    # @!method call(client, arguments = [])
    #   @deprecated use {CallFunction}
    singleton_class.send(:alias_method, :call, :CallFunction)

    # @private wrapper to C code
    def self.call_builtin_wrapper(*args)
      # caller(1) is one of the functions above
      res = caller(2, 1).first.match(BACKTRACE_REGEXP)
      call_builtin(res[1], res[2].to_i, *args)
    end

    private_class_method def self.ask_to_run_debugger?
      Yast.import "Mode"
      !Mode.auto && !Debugger.unwanted? && Debugger.installed?
    end

    private_class_method def self.escape_angle_brackets(str)
      ret.gsub!(/</, "&lt;")
      ret.gsub(/>/, "&gt;")
    end

    # @param [CFA::AugeasParsingError] e the caught exception
    # @return [String] human readable exception description
    private_class_method def self.parsing_error_msg(e)
      msg = "Parse error while reading file #{e.file}<br>" \
            "YaST cannot continue and will quit.<br>" \
            "<br>" \
            "Possible causes and remedies:<br>" \
            "1. You made a mistake when changing the file by hand,<br>" \
            "   the syntax is invalid. Try reverting the changes.<br>" \
            "2. The syntax is in fact valid but YaST does not recognize it.<br>" \
            "   Please report a YaST bug.<br>" \
            "3. YaST made a mistake and wrote invalid syntax earlier.<br>" \
            "   Please report a YaST bug.<br><br>"
      msg + "Caller:  #{escape_angle_brackets(e.backtrace.first)}<br><br>" \
            "Details: #{escape_angle_brackets(e.message)}"
    end

    # @param [Exception] e the caught exception
    # @return [String] human readable exception description
    private_class_method def self.internal_error_msg(e)
      msg = "Internal error. Please report a bug report with logs.<br>" \
        "Run save_y2logs to get complete logs.<br><br>"

      if e.is_a?(ArgumentError) && e.message =~ /invalid byte sequence in UTF-8/
        msg += "A string was encountered that is not valid in UTF-8.<br>" \
               "The system encoding is #{Encoding.locale_charmap.inspect}.<br>" \
               "Refer to https://www.suse.com/support/kb/doc?id=7018056.<br><br>"
      end

      msg + "Caller:  #{escape_angle_brackets(e.backtrace.first)}<br><br>" \
            "Details: #{escape_angle_brackets(e.message)}"
    end

    # Handles a SignalExpection
    private_class_method def self.handle_signal_exception(e)
      signame = Signal.signame(e.signo)
      msg = "YaST received a signal %s and will exit.<br>" % signame
      # sigterm are often sent by user
      if e.signo == 15
        msg += "If termination is not sent by user then please report a bug report with logs.<br>"
      else
        msg += "Please report a bug report with logs.<br>"
      end
      msg += "Run save_y2logs to get complete logs."

      Yast.import "Report"
      Report.Error(msg)
    rescue Exception => e
      Builtins.y2internal("Error reporting failed with '%1'.\n Backtrace:\n%2",
        e.message,
        e.backtrace.join("\n"))
    end

    # Handles a generic Exception
    private_class_method def self.handle_exception(e, client)
      Builtins.y2error("Client %1 failed with '%2' (%3).\nBacktrace:\n%4",
        client,
        e.message,
        e.class.to_s,
        e.backtrace.join("\n"))

      if e.class.to_s == "CFA::AugeasParsingError"
        msg = parsing_error_msg(e)
      else
        msg = internal_error_msg(e)
      end
      msg.gsub!(/\n/, "<br />")

      # Pure approximation here
      # 50 is for usable text area width, +6 is for additional lines like
      # button line, Error caption and so. Whole dialog is at most 20 lines
      # high to fit into screen
      height = [msg.size / 50 + 6, 20].min

      if ask_to_run_debugger?
        Yast.import "Popup"
        Yast.import "Label"
        msg += "<br><br>Start the Ruby debugger now and debug the issue?" \
          " (Experts only!)"

        if Popup.AnyQuestionRichText(Label.ErrorMsg, msg, 60, height,
          Label.YesButton,
          Label.NoButton,
          :focus_none)
          Debugger.start
          # Now you can restart the client and watch it step-by-step with
          # "next"/"step" commands or you can add some breakpoints into
          # the code and use "continue".
          run_client(client)
        end
      else
        Yast.import "Report"
        Report.LongError(msg, height: height)
      end
    rescue Exception => e
      Builtins.y2internal("Error reporting failed with '%1'.Backtrace:\n%2",
        e.message,
        e.backtrace.join("\n"))
    end

    # Handles exception to abort the process
    #
    # In some cases, user can request to directly abort the process (e.g., when
    # it is not possible to acquire a lock). In that situations, the general
    # exception handler should be avoided to not bother the user.
    #
    # @param e [Yast::AbortException]
    # @param client [String]
    private_class_method def self.handle_abort_exception(e, client)
      log.info "To abort the process was requested from client #{client}: #{e.class}: #{e.message}"
    end

    private_class_method def self.check_client_result_type!(result)
      allowed_types = Ops::TYPES_MAP.values.flatten
      allowed_types.delete(::Object) # remove generic type for any

      # check if response is allowed
      allowed = allowed_types.any? { |t| result.is_a? t }

      raise "Invalid type #{result.class} from client #{client}" unless allowed
    end

    # @private wrapper to run client in ruby
    def self.run_client(client)
      Builtins.y2milestone "Call client %1", client
      code = File.read client
      begin
        Debugger.start_from_env
        Profiler.start_from_env
        result = eval(code, GLOBAL_WFM_CONTEXT.binding, client)
        check_client_result_type!(result)

        return result
      # SystemExit < Exception, raised by Kernel#exit
      rescue SystemExit
        raise # something call system exit so do not block it
      # SignalException < Exception
      rescue SignalException => e
        handle_signal_exception(e)
        exit(16)
      rescue AbortException => e
        # Abort was requested
        handle_abort_exception(e, client)
        exit
      rescue Exception => e
        # Don't interfere with RSpec, such as RSpec::Mocks::MockExpectationError
        raise e if e.class.to_s.start_with?("RSpec::")

        handle_exception(e, client)
        false
      end
    end
  end
end
