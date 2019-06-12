#!/usr/bin/env rspec
# typed: false

require_relative "test_helper"

require "yast"

describe Yast do
  describe ".include" do
    it "include methods to target class set as first argument" do
      include_test = Class.new Yast::Module
      include_test_instance = include_test.new

      Yast.include(include_test_instance, "example.rb")

      expect(include_test_instance).to be_respond_to(:test_plus_five)
    end

    it "call its initialization method" do
      include_test = Class.new Yast::Module
      include_test.send(:define_method, :initialize) do
        @test = 5
        # initialization set @test value to 15
        Yast.include self, "example.rb"
      end
      include_test.send(:attr_reader, :test)
      include_test_instance = include_test.new

      expect(include_test_instance.test).to be 15
    end

    it "call its initialization only during first include" do
      include_test = Class.new Yast::Module
      include_test.send(:define_method, :initialize) do
        Yast.include self, "example.rb"
        @test = 5
        # second initialization should no set @test value to 15
        Yast.include self, "example.rb"
      end
      include_test.send(:attr_reader, :test)
      include_test_instance = include_test.new

      expect(include_test_instance.test).to be 5
    end

    it "does not loop endlessly on cyclic includes" do
      expect { Yast.include(Class.new.new, "cyclic_yin.rb") }.not_to raise_error
    end
  end

  describe ".import" do
    context "target module raises exception" do
      it "raises exception with details from original one" do
        expect { Yast.import "RaisingModule" }.to raise_error(/Testing exception/)
      end
    end

    context "target module has invalid signature" do
      it "raises exception with details from original one" do
        expect { Yast.import "InvalidTypeModule" }.to(
          raise_error(/Invalid type 'feels_good\(\)' definition for method\/variable: 'a'/)
        )
      end
    end
  end
end
