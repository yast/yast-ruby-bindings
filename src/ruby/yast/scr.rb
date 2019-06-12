# typed: false
require "yast/builtinx"
require "yast/yast"

module Yast
  # Wrapper class for SCR component in Yast
  # See yast documentation for SCR
  module SCR
    # Reads data
    # @param path[Yast::Path, String] path that is combination of path where agent is
    #   attached and path inside agent
    # @param args additional arguments depending on agent, usually optional
    #
    # @example Get netcards discovered by probe agent
    #    SCR.Read(path(".probe.netcard"))
    # @example Read content of file /tmp/test
    #    SCR.Read(path(".target.string"), "tmp/test")
    def self.Read(path, *args)
      call_builtin_wrapper("Read", Yast.path(path), *args)
    end

    # Writes data
    # @param path[Yast::Path, String] path that is combination of path where agent is
    #   attached and path inside agent
    # @param args additional arguments depending on agent
    # @return [true,false] success
    #
    # @example change default desktop in sysconfig to kde
    #   SCR.Write(path(".sysconfig.windowmanager.DEFAULT_WM"), "kde")
    # @example write string s to file /tmp/f
    #  SCR.Write(path(".target.string"), "/tmp/f", "s")
    def self.Write(path, *args)
      call_builtin_wrapper("Write", Yast.path(path), *args)
    end

    # Executes command
    # @param path[Yast::Path, String] path to agent
    # @param args additional arguments depending on agent
    # @example halt computer
    #    SCR.Execute(path(".target.bash"), "/sbin/halt -f -n -p")
    # @example umount /mnt path
    #    SCR.Execute(path(".target.umount"), "/mnt")
    def self.Execute(path, *args)
      call_builtin_wrapper("Execute", Yast.path(path), *args)
    end

    # Gets array of all children attached directly below path
    # @param path[Yast::Path, String] sub-path where to search for children
    # @return [Array<String>] list of children names
    #
    # @example get all sysconfig agents
    #    SCR.Dir(path(".sysconfig"))
    # @example get all keys in install inf
    #    SCR.Dir(path(".etc.install_inf"))
    def self.Dir(path)
      call_builtin_wrapper("Dir", Yast.path(path))
    end

    # Gets detailled error description from agent
    # @param path[Yast::Path, String] path to agent
    # @return [Hash] with keys "code" and "summary"
    def self.Error(path)
      call_builtin_wrapper("Error", Yast.path(path))
    end

    # Register an agent at given path with description
    #
    # @param path [Yast::Path, String] path to agent
    # @param description [Yast::Term,String] path to file description or direct
    #    term with agent description
    # @return [true,false] if succeed
    def self.RegisterAgent(path, description)
      call_builtin_wrapper("RegisterAgent", Yast.path(path), description)
    end

    # Register new agents. (bnc#245508#c16)
    #
    # Rescan the scrconf registration directories and register any
    # agents at new(!) paths. Agents, even new ones, on paths that
    # are registered already, will not be replaced.  This means that
    # .oes.specific.agent will start to work but something like
    # adding /usr/local/etc/sysconfig to .sysconfig.network would not.
    # @return [true,false] if succeed
    def self.RegisterNewAgents
      call_builtin_wrapper("RegisterNewAgents")
    end

    # Unregister agent from given path
    # @param path [Yast::Path, String] path to agent
    # @return [true,false] if succeed
    def self.UnregisterAgent(path)
      call_builtin_wrapper("UnregisterAgent", Yast.path(path))
    end

    # Unregister all agents
    # @return [true,false] if succeed
    def self.UnregisterAllAgents
      call_builtin_wrapper("UnregisterAllAgents")
    end

    # Unmounts agent. The agent is detached, but when needed it is mounted again automatically.
    #
    # It sends to component result() which force to terminate component.
    # If there is any lazy write, then it is properly finished.
    # @param path[Yast::Path, String] path to agent
    def self.UnmountAgent(path)
      call_builtin_wrapper("UnmountAgent", Yast.path(path))
    end

    # @private wrapper to C bindings
    private_class_method def self.call_builtin_wrapper(*args)
      # caller(1) is one of the functions above
      res = caller(2, 1).first.match(BACKTRACE_REGEXP)
      call_builtin(res[1], res[2].to_i, *args)
    end
  end
end
