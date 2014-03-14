require "yast/builtinx"
require "yast/builtins"
require "yast/ops"

# @private we need it as clients is called in global contenxt
GLOBAL_WFM_CONTEXT = Proc.new {}
module Yast
  # Wrapper class for WFM component in Yast
  # See yast documentation for WFM
  module WFM

    # Returns list of arguments passed to client or element at given index
    #
    # @example Get all args
    #    Yast::WFM.Args
    #
    # @example Get only first argument
    #    Yast::WFM.Args 0
    def self.Args *args
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
    def self.ClientExists client
      call_builtin_wrapper("ClientExists", client)
    end

    # Runs execute on local system agent operating on inst-sys
    #
    # @param path[Yast::Path] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Execute common agent execute
    #
    # @example Run command in bash in inst-sys
    #    Yast::WFM.Execute(Yast::Path.new(".local.bash"), "halt -p")
    def self.Execute path, *args
      call_builtin_wrapper("Execute", path, *args)
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
    # @param path[Yast::Path] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Read common agent read
    #
    # @example Read kernel cmdline
    #    Yast::WFM.Read(path(".local.string"), "/proc/cmdline")
    def self.Read path, *args
      call_builtin_wrapper("Read", path, *args)
    end

    # Closes SCR handle obtained via {SCROpen}
    #
    # If SCR is set as default, then try to switch to another reasonable SCR
    # openned
    def self.SCRClose handle
      call_builtin_wrapper("SCRClose", handle)
    end

    # Gets handle of current default SCR
    def self.SCRGetDefault
      call_builtin_wrapper("SCRGetDefault")
    end

    # Gets name of SCR associated with handle
    #
    # @return [String]
    def self.SCRGetName handle
      call_builtin_wrapper("SCRGetName", handle)
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
    def self.SCROpen name, check_version
      call_builtin_wrapper("SCROpen", name, check_version)
    end

    # Sets the default SCR to given handle
    def self.SCRSetDefault handle
      call_builtin_wrapper("SCRSetDefault", handle)
    end

    # Sets language for translate with optional enconding
    def self.SetLanguage language, *args
      call_builtin_wrapper("SetLanguage", language, *args)
    end

    # Runs write on local system agent operating on inst-sys
    #
    # @param path[Yast::Path] agent path
    # @param args arguments to agent
    #
    # @note very limited use-case. It is needed only if installer switched to
    #   scr on target system and agent from inst-sys must be called
    #
    # @see SCR.Read common agent execute
    #
    # @example Write yast inf file in inst-sys
    #    Yast::WFM.Write(path(".local.string"), "/etc/yast.inf", yast_inf)
    def self.Write path, *args
      call_builtin_wrapper("Write", path, *args)
    end

    # @deprecated use {CallFunction}
    def self.call *args
      call_builtin_wrapper("call", *args)
    end

    # calls client of given name with passed args
    #
    # @param client[String] name of client to run without suffix
    # @param args additional args passed to client, that can be obtained with
    #   {WFM.Args}
    # @return response from client
    #
    # @example call inst_moust client living in $Y2DIR/clients/inst_mouse.rb with parameter true
    #     Yast::WFM.CallFunction("inst_mouse", true)
    def self.CallFunction client, *args
      call_builtin_wrapper("CallFunction", client, *args)
    end

    # @private wrapper to C code
    def self.call_builtin_wrapper *args
      # caller[0] is one of the functions above
      caller[1].match BACKTRACE_REGEXP
      call_builtin($1, $2.to_i, *args)
    end

    # @private wrapper to run client in ruby
    def self.run_client client
      Builtins.y2milestone "Call client %1", client
      code = File.read client
      begin
        result = eval(code, GLOBAL_WFM_CONTEXT.binding, client)

        allowed_types = Ops::TYPES_MAP.values.flatten
        allowed_types.delete(::Object) #remove generic type for any

        # check if response is allowed
        allowed = allowed_types.any? { |t| result.is_a? t }

        raise "Invalid type #{result.class} from client #{client}" unless allowed

        return result
      rescue Exception => e
        begin
          Builtins.y2error("Client call failed with '%1' and backtrace %2",
            e.message,
            e.backtrace
          )
          Yast.import "Report"
          Report.Error "Internal error. Please report a bug report with logs.\n" +
            "Details: #{e.message}\n" +
            "Caller:  #{e.backtrace.first}"
        rescue Exception => e
          Builtins.y2internal("Error reporting failed with '%1' and backtrace %2",
            e.message,
            e.backtrace
          )
        end
        return false
      end
    end
  end
end
