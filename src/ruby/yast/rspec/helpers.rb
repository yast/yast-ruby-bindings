require "yast"

module Yast
  module RSpec
    module Helpers
      # Helper for defining YaST modules which might not be present in
      # the system when running the tests.
      #
      # When the requested module is present in the system then it is imported
      # as usually. If it is missing a substitute definition is created.
      #
      # @note This needs to be called *after* starting code coverage with
      # `SimpleCov.start` so the coverage of the imported modules is correctly
      # counted.
      #
      # @example Mock the `Language` module and the `Language.language` method
      # Yast::RSpec::Helpers.define_yast_module("Language") do
      #   # see modules/Language.rb in yast2-country
      #   module Yast
      #     class LanguageClass < Module
      #       # @return [String]
      #       def language; end
      #     end
      #     Language = LanguageClass.new
      #   end
      # end
      #
      # @example Mock empty `AutoInstall` module
      # Yast::RSpec::Helpers.define_yast_module("AutoInstall")
      #
      # @param name [String] name of the YaST module
      # @param block [Block] optional module definition, it should provide
      #   the same API as the original module, it is enough to define only the
      #   methods used in the tests, if no block is passed an empty module is defined
      def self.define_yast_module(name, &block)
        # sanity check, make sure the code coverage is already running if it is enabled
        if ENV["COVERAGE"] && (!defined?(SimpleCov) || !SimpleCov.running)
          abort "\nERROR: The `define_yast_module` method needs to be called *after* " \
            "enabling the code coverage tracking with `SimpleCov.start`!\n" \
            "  Called from: #{caller(1).first}\n\n"
        end

        # try loading the module, it might be present in the system (running locally
        # or in GitHub Actions), mock it only when missing (e.g. in OBS build)
        Yast.import(name)
        puts "Found module Yast::#{name}"
      rescue NameError
        warn "Module Yast::#{name} not found"
        if block_given?
          block.call
        else
          # create a fake implementation of the module
          Yast.const_set(name.to_sym, Class.new { def self.fake_method; end })
        end
      end
    end
  end
end
