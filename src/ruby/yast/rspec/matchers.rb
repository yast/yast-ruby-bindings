require "rspec"
require "yast"

module Yast
  module RSpec
    # RSpec extension to add YaST-specific matchers
    module Matchers
      # Matches arguments of type YaST::Path whose string representation matches
      # the provided regular expression
      #
      # @example
      #   expect(Yast::SCR).to receive(:Read).with(path_matching(/^\.sysconfig\.nfs/))
      def path_matching(match)
        PathMatchingMatcher.new(match)
      end

      # @private
      class PathMatchingMatcher
        def initialize(expected)
          @expected = Regexp.new(expected)
        end

        def ===(other)
          return false unless other.is_a?(Yast::Path)
          other.to_s =~ @expected ? true : false
        end

        def description
          "path_matching(#{@expected})"
        end
      end
    end
  end
end
