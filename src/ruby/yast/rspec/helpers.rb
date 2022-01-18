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
      # In the substitute definition it is enough to define only the methods
      # used in the tests, you do not need to mirror the complete API.
      #
      # @note This needs to be called *after* starting code coverage with
      #   `SimpleCov.start` so the coverage of the imported modules is correctly
      #   counted.
      #
      # @note You can force using the defined stubs although the modules are
      #   present in the system, this might be useful to actually test the stubs.
      #   Just define the YAST_FORCE_MODULE_STUBS environment variable.
      #
      # @example Mock empty `AutoInstall` module
      # Yast::RSpec::Helpers.define_yast_module("AutoInstall")
      #
      # @example Mock the `Language` module with the `language` method
      # Yast::RSpec::Helpers.define_yast_module("Language", methods: [:language])
      #
      # @example Mock the `AutoinstStorage` module with `Import` taking one parameter
      # Yast::RSpec::Helpers.define_yast_module("AutoinstStorage") do
      #   def Import(_config); end
      # end
      #
      # @param name [String] name of the YaST module
      # @param methods [Array<Symbol>] optional list of defined methods,
      #   the defined methods accept no parameter, if you need a parameter
      #   then define it in the block
      # @param force [Boolean] force creating the fake implementation even when
      #   the module is present in the system, can be also set by the
      #   YAST_FORCE_MODULE_STUBS environment variable. This might be useful
      #   if the module constructor touches the system and it would need a lot
      #   of mocking. But use it carefully, this defeats the purpose of the RSpec
      #   verifying doubles!
      # @param block [Block] optional method definitions, they should provide
      #   the same API as the original module, this can be combined with the
      #   `methods` parameter. The block is evaluated in the context of the
      #   defined modules so you can also use the helpers like `attr_reader`
      #   or define constants.
      def self.define_yast_module(name, methods: [:fake_method], force: false, &block)
        # sanity check, make sure the code coverage is already running if it is enabled
        if ENV["COVERAGE"] && (!defined?(SimpleCov) || !SimpleCov.running)
          abort "\nERROR: The `define_yast_module` method needs to be called *after* " \
            "enabling the code coverage tracking with `SimpleCov.start`!\n" \
            "  Called from: #{caller(1).first}\n\n"
        end

        # force using the full stubs, useful for testing locally when the modules are installed
        if ENV["YAST_FORCE_MODULE_STUBS"] || force
          define_missing_yast_module(name, methods, &block)
        else
          # try loading the module, it might be present in the system (running locally
          # or in GitHub Actions), mock it only when missing (e.g. in OBS build)
          Yast.import(name)
          puts "Found module Yast::#{name}"
        end
      rescue NameError
        define_missing_yast_module(name, methods, &block)
      end

      # create a fake YaST module implementation
      #
      # @param name [String] name
      # @param methods [Array<Symbol>] list of defined methods
      # @param block [Block] optional method definitions
      private_class_method def self.define_missing_yast_module(name, methods, &block)
        warn "Mocking module Yast::#{name}"

        # create a fake implementation of the module
        new_class = Class.new do
          methods.each { |m| define_singleton_method(m) {} }
          instance_eval(&block) if block_given?
        end

        Yast.const_set(name.to_sym, new_class)
      end
    end
  end
end
