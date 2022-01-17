#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec/helpers"

describe Yast::RSpec::Helpers do
  describe ".define_yast_module" do
    context "the requested module is present" do
      it "imports the module" do
        # load the tests/test_module/modules/ExampleTestModule.ycp module
        Yast::RSpec::Helpers.define_yast_module("ExampleTestModule")
        expect(defined?(Yast::ExampleTestModule)).to eq("constant")
      end

      it "does not evaluate the passed block" do
        # load the tests/test_module/modules/ExampleTestModule.ycp module
        expect { |b| Yast::RSpec::Helpers.define_yast_module("ExampleTestModule", &b) }.to_not \
          yield_control
      end
    end

    context "the module is missing" do
      it "evaluates the passed block" do
        expect { |b| Yast::RSpec::Helpers.define_yast_module("NotExistingModule", &b) }.to \
          yield_control
      end

      it "defines an empty fake module when a block is not passed" do
        expect { Yast::RSpec::Helpers.define_yast_module("VerySpecialNotExistingModule") }.to \
          change { defined?(Yast::VerySpecialNotExistingModule) }.from(nil).to("constant")
      end
    end
  end
end
