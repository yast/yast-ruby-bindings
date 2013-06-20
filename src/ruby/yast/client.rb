require "yast/yast"
require "yast/i18n"
require "yast/exportable"
require "yast/ui_shortcuts"

module Yast
  class Client
    include I18n
    extend Exportable
    include Yast
    include UIShortcuts
  end
end
