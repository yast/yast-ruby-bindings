require "rspec"
require "yast"

module Yast
  module RSpec
    # RSpec extension adding commodity shortcuts to enhance readability
    module Shortcuts
      # Shortcut for generating Yast::Path objects
      #
      # @param route [String] textual representation of the path
      # @return [Yast::Path] the corresponding Path object
      def path(route)
        Yast::Path.new(route)
      end
    end
  end
end
