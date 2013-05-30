require "ycp/ycp"
require "ycp/i18n"
require "ycp/exportable"
require "ycp/ui"

module YCP
  class ModuleBase
    include I18n
    extend Exportable
    include YCP
    include UI
  end
end
