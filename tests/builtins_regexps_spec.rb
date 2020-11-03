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
    def regexpsub(input, pattern, output)
      Yast::Builtins.regexpsub(input, pattern, output)
    end

    it "handles nil in INPUT or PATTERN, returning nil" do
      expect(regexpsub(nil, "I", "profit")).to eq(nil)
      expect(regexpsub(nil, "I", nil)).to eq(nil)
      expect(regexpsub("team", nil, "profit")).to eq(nil)
      expect(regexpsub("team", nil, nil)).to eq(nil)
    end

    it "raises TypeError if OUTPUT is nil" do
      expect { regexpsub("team", "I", nil) }.to raise_error(TypeError)
    end

    it "returns nil if there's no match" do
      expect(regexpsub("team", "I", "profit")).to eq(nil)
    end

    it "returns OUTPUT (not INPUT!) if there is a match" do
      expect(regexpsub("lose", "s", "v")).to eq("v")
    end

    it "substitutes match groups in OUTPUT" do
      expect(regexpsub("lose", "(.*)s(.*)", "\\1v\\2")).to eq("love")
    end

    it "works on legacy tests" do
      expect(Yast::Builtins.regexpsub(nil, nil, nil)).to eq(nil)

      # from Yast documentation
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e")).to eq("s_aaab_e")
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ba)", "s_\\1_e")).to eq(nil)

      # from sysconfig remove whitespaces
      pattern = "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$"
      expect(Yast::Builtins.regexpsub(" lest test\tsrst\t", pattern, "\\1"))
        .to eq("lest test\tsrst")
      expect(Yast::Builtins.regexpsub("", pattern, "\\1")).to eq("")
      expect(Yast::Builtins.regexpsub("  \t  ", pattern, "\\1")).to eq("")

      # the result must be UTF-8 string
      expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e").encoding).to eq(Encoding::UTF_8)
    end
  end

  describe ".regexptokenize" do
    it "works as expected" do
      expect(Yast::Builtins.regexptokenize("aaabb7b", "(.*[0-9]).*")).to eq(["aaabb7"])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ab)(.*)")).to eq(["aaab", "bb"])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*")).to eq([])
      expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*(")).to eq(nil)

      # the result must be UTF-8 string
      expect(Yast::Builtins.regexptokenize("aaabb7b", "(.*[0-9]).*").first.encoding).to eq(Encoding::UTF_8)
    end
  end
end
