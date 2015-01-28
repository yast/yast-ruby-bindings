require "rspec"
require "yast"

module Yast
  module RSpec
    # RSpec extension adding commodity shortcuts to enhance readability
    module Shortcuts
      include Yast::UIShortcuts

      # Shortcut for generating Yast::Path objects
      #
      # @param route [String] textual representation of the path
      # @return [Yast::Path] the corresponding Path object
      def path(route)
        Yast::Path.new(route)
      end

      # Shortcut for generating Yast::Term objects
      #
      # @param args parameter for term initialization
      # @return [Yast::Term] the corresponding Term object
      def term(*args)
        Yast::Term.new(*args)
      end
    end
  end
end
