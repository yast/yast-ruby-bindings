require "ycp/ycp"
require "ycp/i18n"
require "ycp/exportable"
require "ycp/ui"

module YCP
  class Module
    include I18n
    extend Exportable
    include YCP
    include UI
  end
end
