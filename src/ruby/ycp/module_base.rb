require "ycp/ycp"
require "ycp/i18n"
require "ycp/exportable"

module YCP
  class ModuleBase
    include I18n
    extend Exportable
    include YCP
  end
end
