require "yast"
require "erb"

class Y2ERB
  def self.render(path)
    # TODO: detect url in path and download it
    env = TemplateEnvironment.new
    template = ERB.new(File.read(path))
    template.result(env.public_binding)
    # TODO write directly to modified?
  end

  class TemplateEnvironment
    def hardware
      @hardware ||= Yast::SCR.Read(Yast::Path.new(".probe"))
    end

    # expose method bindings
    def public_binding
      binding
    end
  end
end
