require "ycp/ycp"
require "ycp/i18n"
require "ycp/exportable"

module YCP
  class ClientBase
    include I18n
    extend Exportable
    include YCP
  end
end
