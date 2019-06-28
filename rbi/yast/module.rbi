# typed: strong

module Yast
  class Module
    include I18n
    extend Exportable
    include Yast
    include UIShortcuts
  end
end
