require "ycp/ycp"
require "ycp/i18n"
require "ycp/exportable"
require "ycp/ui_shortcuts"

module YCP
  class Client
    include I18n
    extend Exportable
    include YCP
    include UIShortcuts
  end
end
