#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"

describe "Yast::Builtins regular expresion methods" do
  describe ".regexpmatch" do
    it "works as expected" do
      expect(Yast::Builtins.regexpmatch(nil, nil)).to eq(nil)
      expect(Yast::Builtins.regexpmatch("", nil)).to eq(nil)
      expect(Yast::Builtins.regexpmatch("", "")).to eq(true)
      expect(Yast::Builtins.regexpmatch("abc", "")).to eq(true)

      expect(Yast::Builtins.regexpmatch("abc", "^a")).to eq(true)
      expect(Yast::Builtins.regexpmatch("abc", "c$")).to eq(true)
      expect(Yast::Builtins.regexpmatch("abc", "^[^][%]bc$")).to eq(true)
    end
  end

  describe ".regexppos" do
    it "works as expected" do
      expect(Yast::Builtins.regexppos(nil, nil)).to eq(nil)
      expect(Yast::Builtins.regexppos("", "")).to eq([0, 0])

      # from Yast documentation
      expect(Yast::Builtins.regexppos("abcd012efgh345", "[0-9]+")).to eq([4, 3])
      expect(Yast::Builtins.regexppos("aaabbb", "[0-9]+")).to eq([])
    end
  end

  describe ".regexpsub" do
    it "works as expected" do
      expect(Yast::Builtins.regexpsub(nil, nil, nil)).to eq(nil)

      # from Yast documentation
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e")).to eq("s_aaab_e")
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ba)", "s_\\1_e")).to eq(nil)

      #from sysconfig remove whitespaces
      expect(Yast::Builtins.regexpsub(" lest test\tsrst\t", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("lest test\tsrst")
      expect(Yast::Builtins.regexpsub("", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("")
      expect(Yast::Builtins.regexpsub("  \t  ", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("")

      # the result must be UTF-8 string
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e").encoding).to eq(Encoding::UTF_8)
    end
  end

  describe ".regexptokenize" do
    it "works as expected" do
      expect(Yast::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*")).to eq(["aaabbB"])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ab)(.*)")).to eq(["aaab", "bb"])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*")).to eq([])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*(")).to eq(nil)

      # the result must be UTF-8 string
      expect(Yast::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*").first.encoding).to eq(Encoding::UTF_8)
    end
  end
end
