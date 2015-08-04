#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"
require "yast/path"
require "yast/term"

describe "Yast::Builtins type casting methods" do
  describe ".toset" do
    it "works as expected" do
      expect(Yast::Builtins.toset(nil)).to eq(nil)

      expect(Yast::Builtins.toset([])).to eq([])
      expect(Yast::Builtins.toset(["A"])).to eq(["A"])
      expect(Yast::Builtins.toset(["Z", "A"])).to eq(["A", "Z"])
      expect(Yast::Builtins.toset([3, 2, 2, 1, 2, 1, 3, 1, 3, 3])).to eq([1, 2, 3])

      expect(Yast::Builtins.toset([1, 5, 3, 2, 3, true, false, true])).to eq([false, true, 1, 2, 3, 5])
    end
  end

  describe ".tostring" do
    TOSTRING_TEST_DATA = [
      [nil, "nil"],
      [true, "true"],
      [false, "false"],
      ["test", "test"],
      [:test, "`test"],
      [1, "1"],
      [1.453, "1.453"],
      [["test", :lest], '["test", `lest]'],
      [Yast::Path.new(".etc.syconfig.\"-arg\""), ".etc.syconfig.\"-arg\""],
      [Yast::Term.new(:id, ["test", :lest]), "`id ([\"test\", `lest])"],
      [{ test: "data" }, "$[`test:\"data\"]"]
    ]

    it "works as expected" do
      TOSTRING_TEST_DATA.each do |input, result|
        expect(Yast::Builtins.tostring(input)).to eq(result)
      end
    end

    it "honors precision" do
      expect(Yast::Builtins.tostring(1.453, 1)).to eq("1.5")
    end
  end

  describe ".tohexstring" do
    it "works as expected" do
      expect(Yast::Builtins.tohexstring(nil)).to eq(nil)
      expect(Yast::Builtins.tohexstring(nil, nil)).to eq(nil)
      expect(Yast::Builtins.tohexstring(0)).to eq("0x0")
      expect(Yast::Builtins.tohexstring(10)).to eq("0xa")
      expect(Yast::Builtins.tohexstring(255)).to eq("0xff")
      expect(Yast::Builtins.tohexstring(222_222)).to eq("0x3640e")

      expect(Yast::Builtins.tohexstring(31, 0)).to eq("0x1f")
      expect(Yast::Builtins.tohexstring(31, 1)).to eq("0x1f")
      expect(Yast::Builtins.tohexstring(31, 4)).to eq("0x001f")
      expect(Yast::Builtins.tohexstring(31, 6)).to eq("0x00001f")

      expect(Yast::Builtins.tohexstring(31, -1)).to eq("0x1f")
      expect(Yast::Builtins.tohexstring(31, -3)).to eq("0x1f ")

      expect(Yast::Builtins.tohexstring(-3)).to eq("0xfffffffffffffffd")
      expect(Yast::Builtins.tohexstring(-3, 5)).to eq("0xfffffffffffffffd")
      expect(Yast::Builtins.tohexstring(-3, 18)).to eq("0x00fffffffffffffffd")
      expect(Yast::Builtins.tohexstring(-3, 22)).to eq("0x000000fffffffffffffffd")

      expect(Yast::Builtins.tohexstring(-3, -16)).to eq("0xfffffffffffffffd")
      expect(Yast::Builtins.tohexstring(-3, -17)).to eq("0xfffffffffffffffd ")
      expect(Yast::Builtins.tohexstring(-3, -22)).to eq("0xfffffffffffffffd      ")
    end
  end

  describe ".tointeger" do
    it "works as expected" do
      expect(Yast::Builtins.tointeger(nil)).to eq(nil)
      expect(Yast::Builtins.tointeger("")).to eq(nil)
      expect(Yast::Builtins.tointeger("foo")).to eq(nil)
      expect(Yast::Builtins.tointeger(120)).to eq(120)
      expect(Yast::Builtins.tointeger("120")).to eq(120)
      expect(Yast::Builtins.tointeger("  120asdf")).to eq(120)
      expect(Yast::Builtins.tointeger(120.0)).to eq(120)
      expect(Yast::Builtins.tointeger("0x20")).to eq(32)
      expect(Yast::Builtins.tointeger(" 0x20")).to eq(0)
      expect(Yast::Builtins.tointeger("0x20Z")).to eq(32)
      expect(Yast::Builtins.tointeger("010")).to eq(8)
      expect(Yast::Builtins.tointeger("-10")).to eq(-10)

      # weird Yast cases
      expect(Yast::Builtins.tointeger("-0x20")).to eq(0)
      expect(Yast::Builtins.tointeger(" 0x20")).to eq(0)
      expect(Yast::Builtins.tointeger(" 020")).to eq(20)
      expect(Yast::Builtins.tointeger("-020")).to eq(-20)
      expect(Yast::Builtins.tointeger("-0020")).to eq(-20)
    end
  end

  describe ".tofloat" do
    TOFLOAT_TESTDATA = [
      [1, 1.0],
      [nil, nil],
      ["42", 42.0],
      ["89.3", 89.3],
      ["test", 0.0],
      [:test, nil]
    ]

    it "works as expected" do
      TOFLOAT_TESTDATA.each do |value, result|
        expect(Yast::Builtins.tofloat(value)).to eq(result)
      end
    end
  end

  describe ".topath" do
    it "works as expected" do
      expect(Yast::Builtins.topath(nil)).to eq(nil)

      expect(Yast::Builtins.topath(Yast::Path.new(".etc"))).to eq(Yast::Path.new(".etc"))

      expect(Yast::Builtins.topath(".etc")).to eq(Yast::Path.new(".etc"))

      expect(Yast::Builtins.topath("etc")).to eq(Yast::Path.new(".etc"))
    end
  end

  describe "Float.tolstring" do
    it "works as expected" do
      old_lang = ENV["LANG"]
      lc_all = ENV["LC_ALL"]
      ENV["LANG"] = "cs_CZ.utf-8"
      ENV["LC_ALL"] = "cs_CZ.utf-8"
      ret = Yast::Builtins::Float.tolstring(0.52, 1)
      expect(ret).to eq("0,5")
      expect(ret.encoding).to eq(Encoding::UTF_8)
      ENV["LANG"] = old_lang
      ENV["LC_ALL"] = lc_all
    end
  end

  describe "toterm" do
    TOTERM_TEST_DATA = [
      ["test", Yast::Term.new(:test)],
      [:test, Yast::Term.new(:test)],
      [[:test, [:lest, :srst]], Yast::Term.new(:test, :lest, :srst)],
      [[Yast::Term.new(:test)], Yast::Term.new(:test)]
    ]

    it "works as expected" do
      TOTERM_TEST_DATA.each do |input, res|
        expect(Yast::Builtins.toterm(*input)).to eq(res)
      end
    end
  end
end
