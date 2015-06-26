#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"

describe Yast::Builtins::Float do
  describe ".abs" do
    it "works as expected" do
      expect(Yast::Builtins::Float.abs(nil)).to eq(nil)

      expect(Yast::Builtins::Float.abs(-5.4)).to eq(5.4)
    end
  end

  describe ".ceil" do
    it "works as expected" do
      expect(Yast::Builtins::Float.ceil(nil)).to eq(nil)

      expect(Yast::Builtins::Float.ceil(-5.4)).to eq(-5.0)

      expect(Yast::Builtins::Float.ceil(5.4)).to eq(6.0)
      expect(Yast::Builtins::Float.ceil(5.4).class).to eq(Float)
    end
  end

  describe ".floor" do
    it "works as expected" do
      expect(Yast::Builtins::Float.floor(nil)).to eq(nil)

      expect(Yast::Builtins::Float.floor(-5.4)).to eq(-6.0)

      expect(Yast::Builtins::Float.floor(5.4)).to eq(5.0)
      expect(Yast::Builtins::Float.floor(5.4).class).to eq(Float)
    end
  end

  describe ".pow" do
    it "works as expected" do
      expect(Yast::Builtins::Float.pow(nil,10.0)).to eq(nil)

      expect(Yast::Builtins::Float.pow(10.0,3.0)).to eq(1000.0)
      expect(Yast::Builtins::Float.pow(10.0,3.0).class).to eq(Float)
    end
  end

  describe ".trunc" do
    it "works as expected" do
      expect(Yast::Builtins::Float.trunc(nil)).to eq(nil)

      expect(Yast::Builtins::Float.trunc(-5.4)).to eq(-5.0)

      expect(Yast::Builtins::Float.trunc(5.6)).to eq(5.0)
      expect(Yast::Builtins::Float.trunc(5.4).class).to eq(Float)
    end
  end
end
