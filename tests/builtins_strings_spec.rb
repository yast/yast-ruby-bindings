#!/usr/bin/env rspec
# typed: false
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"

describe "Yast::Builtins string methods" do
  describe ".substring" do
    it "works as expected" do
      str = "12345"

      expect(Yast::Builtins.substring(str, 0)).to eq(str)
      expect(Yast::Builtins.substring(str, 2)).to eq("345")

      expect(Yast::Builtins.substring(str, 2, 0)).to eq("")
      expect(Yast::Builtins.substring(str, 2, 2)).to eq("34")

      # tests from Yast documentation
      expect(Yast::Builtins.substring("some text", 5)).to eq("text")
      expect(Yast::Builtins.substring("some text", 42)).to eq("")
      expect(Yast::Builtins.substring("some text", 5, 2)).to eq("te")
      expect(Yast::Builtins.substring("some text", 42, 2)).to eq("")
      expect(Yast::Builtins.substring("123456789", 2, 3)).to eq("345")

      # check some corner cases to be Yast compatible
      expect(Yast::Builtins.substring(nil, 2)).to eq(nil)
      expect(Yast::Builtins.substring(str, -1)).to eq("")
      expect(Yast::Builtins.substring(str, 2, -1)).to eq("345")

      expect(Yast::Builtins.substring(str, nil)).to eq(nil)
      expect(Yast::Builtins.substring(str, nil, nil)).to eq(nil)
      expect(Yast::Builtins.substring(str, 1, nil)).to eq(nil)
    end
  end

  describe ".issubstring" do
    it "works as expected" do
      expect(Yast::Builtins.issubstring(nil, nil)).to eq(nil)
      expect(Yast::Builtins.issubstring("", nil)).to eq(nil)
      expect(Yast::Builtins.issubstring(nil, "")).to eq(nil)

      expect(Yast::Builtins.issubstring("abcd", "bc")).to eq(true)
      expect(Yast::Builtins.issubstring("ABC", "abc")).to eq(false)
      expect(Yast::Builtins.issubstring("a", "a")).to eq(true)
      expect(Yast::Builtins.issubstring("", "")).to eq(true)
    end
  end

  describe ".splitstring" do
    it "works as expected" do
      expect(Yast::Builtins.splitstring(nil, nil)).to eq(nil)
      expect(Yast::Builtins.splitstring("", nil)).to eq(nil)
      expect(Yast::Builtins.splitstring(nil, "")).to eq(nil)
      expect(Yast::Builtins.splitstring("", "")).to eq([])
      expect(Yast::Builtins.splitstring("ABC", "")).to eq([])

      expect(Yast::Builtins.splitstring("a b c d", " ")).to eq(["a", "b", "c", "d"])
      expect(Yast::Builtins.splitstring("ABC", "abc")).to eq(["ABC"])

      expect(Yast::Builtins.splitstring("a   a", " ")).to eq(["a", "", "", "a"])
      expect(Yast::Builtins.splitstring("text/with:different/separators", "/:"))
        .to eq(["text", "with", "different", "separators"])
    end
  end

  describe ".mergestring" do
    it "works as expected" do
      expect(Yast::Builtins.mergestring(nil, nil)).to eq(nil)
      expect(Yast::Builtins.mergestring([], nil)).to eq(nil)
      expect(Yast::Builtins.mergestring(nil, "")).to eq(nil)

      expect(Yast::Builtins.mergestring([], "")).to eq("")
      expect(Yast::Builtins.mergestring(["A", "B", "C"], "")).to eq("ABC")
      expect(Yast::Builtins.mergestring(["A", "B", "C"], " ")).to eq("A B C")

      expect(Yast::Builtins.mergestring(["a", "b", "c", "d"], " ")).to eq("a b c d")
      expect(Yast::Builtins.mergestring(["ABC"], "abc")).to eq("ABC")
      expect(Yast::Builtins.mergestring(["a", "", "", "a"], " ")).to eq("a   a")

      # tests from Yast documentation
      expect(Yast::Builtins.mergestring(["", "abc", "dev", "ghi"], "/")).to eq("/abc/dev/ghi")
      expect(Yast::Builtins.mergestring(["abc", "dev", "ghi", ""], "/")).to eq("abc/dev/ghi/")
      expect(Yast::Builtins.mergestring([1, "a", 3], ".")).to eq("1.a.3")
      expect(Yast::Builtins.mergestring(["1", "a", "3"], ".")).to eq("1.a.3")
      expect(Yast::Builtins.mergestring([], ".")).to eq("")
      expect(Yast::Builtins.mergestring(["abc", "dev", "ghi"], "")).to eq("abcdevghi")
      expect(Yast::Builtins.mergestring(["abc", "dev", "ghi"], "123")).to eq("abc123dev123ghi")
    end
  end

  describe ".timestring" do
    it "works as expected" do
      expect(Yast::Builtins.timestring(nil, nil, nil)).to eq(nil)

      # disabled: system dependent (depends on the current system time zone),
      # fails if the current offset is not UTC+2:00
      # expect(Yast::Builtins.timestring("%c", 1367839796, false)).to eq("Mon May  6 13:29:56 2013")
      expect(Yast::Builtins.timestring("%c", 1_367_839_796, true)).to eq("Mon May  6 11:29:56 2013")
      expect(Yast::Builtins.timestring("%Y%m%d", 1_367_839_796, false)).to eq("20130506")
    end
  end

  describe ".tolower" do
    it "works as expected" do
      expect(Yast::Builtins.tolower(nil)).to eq(nil)
      expect(Yast::Builtins.tolower("")).to eq("")
      expect(Yast::Builtins.tolower("abc")).to eq("abc")
      expect(Yast::Builtins.tolower("ABC")).to eq("abc")
      expect(Yast::Builtins.tolower("ABCÁÄÖČ")).to eq("abcÁÄÖČ")
    end
  end

  describe ".toupper" do
    it "works as expected" do
      expect(Yast::Builtins.toupper(nil)).to eq(nil)
      expect(Yast::Builtins.toupper("")).to eq("")
      expect(Yast::Builtins.toupper("ABC")).to eq("ABC")
      expect(Yast::Builtins.toupper("abc")).to eq("ABC")
      expect(Yast::Builtins.toupper("abcáäöč")).to eq("ABCáäöč")
    end
  end

  describe ".toascii" do
    it "works as expected" do
      expect(Yast::Builtins.toascii(nil)).to eq(nil)
      expect(Yast::Builtins.toascii("")).to eq("")
      expect(Yast::Builtins.toascii("abc123XYZ")).to eq("abc123XYZ")
      expect(Yast::Builtins.toascii("áabcě123čXYZŽž")).to eq("abc123XYZ")
    end
  end
end
