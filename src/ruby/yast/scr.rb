require "yast/builtinx"

module Yast
  module SCR
    def self.Read *args
      call_builtin_wrapper("Read",*args)
    end

    def self.Write *args
      call_builtin_wrapper("Write", *args)
    end

    def self.Execute *args
      call_builtin_wrapper("Execute", *args)
    end

    def self.Dir *args
      call_builtin_wrapper("Dir", *args)
    end

    def self.Error *args
      call_builtin_wrapper("Error", *args)
    end

    def self.RegisterAgent *args
      call_builtin_wrapper("RegisterAgent", *args)
    end

    def self.RegisterNewAgents *args
      call_builtin_wrapper("RegisterNewAgents", *args)
    end

    def self.UnregisterAgent *args
      call_builtin_wrapper("UnregisterAgent", *args)
    end

    def self.UnregisterAllAgents *args
      call_builtin_wrapper("UnregisterAllAgents", *args)
    end

    def self.UnmountAgent *args
      call_builtin_wrapper("UnmountAgent", *args)
    end

    # FIXME duplicate of code in wfm
    def self.call_builtin_wrapper *args
      from = caller[1]          # caller[0] is one of the functions above
      filename = from[/^[^:]+/]
      lineno = from[/:\d+/][1..-1].to_i
      call_builtin(filename,lineno,*args)
    end

  end
end
