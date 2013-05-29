require "ycp/builtinx"
require "ycp/builtins"

#we need it as clients is called in global contenxt
GLOBAL_WFM_CONTEXT = Proc.new {}
module YCP
  module WFM
    def self.Args *args
      call_builtin_wrapper("Args", *args)
    end

    def self.ClientExists *args
      call_builtin_wrapper("ClientExists", *args)
    end

    def self.Execute *args
      call_builtin_wrapper("Execute", *args)
    end

    def self.GetEncoding *args
      call_builtin_wrapper("GetEncoding", *args)
    end

    def self.GetEnvironmentEncoding *args
      call_builtin_wrapper("GetEnvironmentEncoding", *args)
    end

    def self.GetLanguage *args
      call_builtin_wrapper("GetLanguage", *args)
    end

    def self.Read *args
      call_builtin_wrapper("Read", *args)
    end

    def self.SCRClose *args
      call_builtin_wrapper("SCRClose", *args)
    end

    def self.SCRGetDefault *args
      call_builtin_wrapper("SCRGetDefault", *args)
    end

    def self.SCRGetName *args
      call_builtin_wrapper("SCRGetName", *args)
    end

    def self.SCROpen *args
      call_builtin_wrapper("SCROpen", *args)
    end

    def self.SCRSetDefault *args
      call_builtin_wrapper("SCRSetDefault", *args)
    end

    def self.SetLanguage *args
      call_builtin_wrapper("SetLanguage", *args)
    end

    def self.Write *args
      call_builtin_wrapper("Write", *args)
    end

    def self.call *args
      call_builtin_wrapper("call", *args)
    end

    def self.CallFunction *args
      call_builtin_wrapper("CallFunction", *args)
    end

    def self.call_builtin_wrapper *args
      from = caller[1]          # caller[0] is one of the functions above
      filename = from[/^[^:]+/]
      lineno = from[/:\d+/][1..-1].to_i
      call_builtin(filename,lineno,*args)
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
