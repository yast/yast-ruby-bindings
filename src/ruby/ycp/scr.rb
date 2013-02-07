require "ycp/scrx"

module YCP
  module SCR
    def self.Read *args
      call_builtin("Read",*args)
    end

    def self.Write *args
      call_builtin("Write", *args)
    end

    def self.Execute *args
      call_builtin("Execute", *args)
    end

    def self.Dir *args
      call_builtin("Dir", *args)
    end

    def self.Error *args
      call_builtin("Error", *args)
    end

    def self.RegisterAgent *args
      call_builtin("RegisterAgent", *args)
    end

    def self.RegisterNewAgents *args
      call_builtin("RegisterNewAgents", *args)
    end

    def self.UnregisterAgent *args
      call_builtin("UnregisterAgent", *args)
    end

    def self.UnregisterAllAgents *args
      call_builtin("UnregisterAllAgents", *args)
    end

    def self.UnmountAgent *args
      call_builtin("UnmountAgent", *args)
    end
  end
end
