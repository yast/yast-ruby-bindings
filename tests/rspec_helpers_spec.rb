#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec/helpers"

describe Yast::RSpec::Helpers do
  describe ".define_yast_module" do
    context "the requested module is present" do
      after do
        # unload the testing YaST module
        Yast.send(:remove_const, :ExampleTestModule) if defined?(Yast::ExampleTestModule)
      end

      it "imports the module" do
        # make sure the module was not accidentally loaded before
        Yast.send(:remove_const, :ExampleTestModule) if defined?(Yast::ExampleTestModule)

        # load the tests/test_module/modules/ExampleTestModule.ycp module
        expect { Yast::RSpec::Helpers.define_yast_module("ExampleTestModule") }.to \
          change { defined?(Yast::ExampleTestModule) }.from(nil).to("constant")

        # check that the testing module is really loaded
        expect(Yast::ExampleTestModule.respond_to?(:arch_short)).to be true
      end

      it "does not evaluate the passed block" do
        # load the tests/test_module/modules/ExampleTestModule.ycp module
        expect { |b| Yast::RSpec::Helpers.define_yast_module("ExampleTestModule", &b) }.to_not \
          yield_control
      end

      it "creates the fake implementation when forced" do
        Yast::RSpec::Helpers.define_yast_module("ExampleTestModule", methods: [:foo], force: true)
        expect(Yast::ExampleTestModule.respond_to?(:foo)).to be true
      end
    end

    context "the module is missing" do
      after do
        # cleanup the defined testing YaST module
        Yast.send(:remove_const, :VerySpecialNotExistingModule) if defined?(Yast::VerySpecialNotExistingModule)
      end

      it "defines an empty fake module" do
        expect { Yast::RSpec::Helpers.define_yast_module("VerySpecialNotExistingModule") }.to \
          change { defined?(Yast::VerySpecialNotExistingModule) }.from(nil).to("constant")
      end

      it "evaluates the passed block" do
        expect { |b| Yast::RSpec::Helpers.define_yast_module("VerySpecialNotExistingModule", &b) }.to \
          yield_control
      end

      it "defines the requested module methods" do
        Yast::RSpec::Helpers.define_yast_module("VerySpecialNotExistingModule", methods: [:foo])

        expect(Yast::VerySpecialNotExistingModule.respond_to?(:foo)).to be true
        # by default no parameter accepted
        expect(Yast::VerySpecialNotExistingModule.method(:foo).arity).to eq(0)
      end

      it "defines the methods passed in the block" do
        Yast::RSpec::Helpers.define_yast_module("VerySpecialNotExistingModule") do
          def foo(_bar, _baz); end
        end

        expect(Yast::VerySpecialNotExistingModule.respond_to?(:foo)).to be true
        # accepts two parameters
        expect(Yast::VerySpecialNotExistingModule.method(:foo).arity).to eq(2)
      end
    end
  end
end
