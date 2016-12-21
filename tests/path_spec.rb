#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"

require "yast/path"

describe "Yast::Path" do
  describe "#initialize" do
    it "works for simple paths" do
      expect(Yast::Path.new(".etc").to_s).to eq(".etc")
    end
    it "works for complex paths" do
      expect(Yast::Path.new(".et?c").to_s).to eq('."et?c"')
    end
  end

  describe ".from_string" do
    it "works for simple paths" do
      expect(Yast::Path.from_string("etc").to_s).to eq(".\"etc\"")
    end
    it "works for complex paths" do
      expect(Yast::Path.from_string("et?c").to_s).to eq('."et?c"')
    end
  end

  describe "#+" do
    it "works" do
      root = Yast::Path.new "."
      etc = Yast::Path.new ".etc"
      sysconfig = Yast::Path.new ".sysconfig"
      expect((etc + sysconfig).to_s).to eq(".etc.sysconfig")
      expect((etc + "sysconfig").to_s).to eq('.etc."sysconfig"')
      expect((root + root).to_s).to eq(".")
      expect((root + etc).to_s).to eq(".etc")
      expect((etc + root).to_s).to eq(".etc")
    end
  end

  describe "#<=>" do
    it "works for equality with Path" do
      expect(Yast::Path.new(".\"\x1A\"")).to eq(Yast::Path.new(".\"\x1a\""))
      expect(Yast::Path.new(".\"A\"")).to eq(Yast::Path.new(".\"\x41\""))
      expect(Yast::Path.new(".")).to_not eq(Yast::Path.new(".\"\""))
    end

    it "works for ordering Paths" do
      expect(Yast::Path.new(".ba")).to be >= Yast::Path.new('."a?"')
      expect(Yast::Path.new('."b?"')).to be >= Yast::Path.new(".ab")
    end

    # bsc#933470
    it "survives comparison with a non-Path" do
      expect(Yast::Path.new(".foo") <=> 42).to eq nil
    end
  end

  describe "#clone" do
    it "works" do
      etc = Yast::Path.new ".etc.sysconfig.DUMP"
      expect(etc.clone.to_s).to eq(".etc.sysconfig.DUMP")
    end
  end
end
