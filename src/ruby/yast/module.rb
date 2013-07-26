require "yast/yast"
require "yast/i18n"
require "yast/exportable"
require "yast/ui_shortcuts"

module Yast
  # Base class for all modules. Its main purpose is to have one place to modify all modules.
  class Module
    include I18n
    extend Exportable
    include Yast
    include UIShortcuts
  end
end
