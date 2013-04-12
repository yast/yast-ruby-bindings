require "ycp/builtinx"
require "ycp/builtins"

#we need it as clients is called in global contenxt
GLOBAL_WFM_CONTEXT = Proc.new {}
module YCP
  module WFM
    def self.Args
      call_builtin("Args")
    end

    def self.ClientExists *args
      call_builtin("ClientExists", *args)
    end

    def self.Execute *args
      call_builtin("Execute", *args)
    end

    def self.GetEncoding *args
      call_builtin("GetEncoding", *args)
    end

    def self.GetEnvironmentEncoding *args
      call_builtin("GetEnvironmentEncoding", *args)
    end

    def self.GetLanguage *args
      call_builtin("GetLanguage", *args)
    end

    def self.Read *args
      call_builtin("Read", *args)
    end

    def self.SCRClose *args
      call_builtin("SCRClose", *args)
    end

    def self.SCRGetDefault *args
      call_builtin("SCRGetDefault", *args)
    end

    def self.SCRGetName *args
      call_builtin("SCRGetName", *args)
    end

    def self.SCROpen *args
      call_builtin("SCROpen", *args)
    end

    def self.SCRSetDefault *args
      call_builtin("SCRSetDefault", *args)
    end

    def self.SetLanguage *args
      call_builtin("SetLanguage", *args)
    end

    def self.Write *args
      call_builtin("Write", *args)
    end

    def self.call *args
      call_builtin("call", *args)
    end

    def self.CallFunction *args
      call_builtin("CallFunction", *args)
    end

    def self.run_client client
      Builtins.y2milestone "Call client %1", client
      code = File.read client
      begin
        return eval(code, GLOBAL_WFM_CONTEXT.binding, client)
      rescue Exception => e
        Builtins.y2error("Client call failed with %1 and backtrace %2",
          e.message,
          e.backtrace
        )
        return nil
      end
    end
  end
end
