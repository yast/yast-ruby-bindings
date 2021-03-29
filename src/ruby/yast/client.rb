# typed: strong
require "yast/yast"
require "yast/i18n"
require "yast/exportable"
require "yast/ui_shortcuts"

module Yast
  # Base class for all clients. Its main purpose is to have one place to modify all clients.
  class Client
    include I18n
    include Yast
    include UIShortcuts
  end
end
