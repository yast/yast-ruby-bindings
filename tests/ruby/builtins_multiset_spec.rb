#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"

describe Yast::Builtins::Multiset do
  describe ".union" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.union([1, 2], [2, 3])).to eq([1, 2, 3])
    end
  end

  describe ".includes" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.includes([1, 2], [2, 3])).to eq(false)
      expect(Yast::Builtins::Multiset.includes([1, 2], [2, 2])).to eq(false)
      expect(Yast::Builtins::Multiset.includes([1, 2], [2])).to eq(true)
    end
  end

  describe ".difference" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.difference([1, 2], [2, 3])).to eq([1])
    end
  end

  describe ".symmetric_difference" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.symmetric_difference([1, 2], [2, 3])).to eq([1, 3])
      expect(Yast::Builtins::Multiset.symmetric_difference([1, 2], [2, 2])).to eq([1, 2])
      expect(Yast::Builtins::Multiset.symmetric_difference([1, 1, 2], [2, 2, 2])).to eq([1, 1, 2, 2])
    end
  end

  describe ".intersection" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.intersection([1, 2], [2, 3])).to eq([2])
      expect(Yast::Builtins::Multiset.intersection([1, 2, 2], [2, 2, 3])).to eq([2, 2])
    end
  end

  describe ".union" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.union([1, 2], [2, 3])).to eq([1, 2, 3])
      expect(Yast::Builtins::Multiset.union([1, 2, 2], [2, 2, 3])).to eq([1, 2, 2, 3])
    end
  end

  describe ".merge" do
    it "works as expected" do
      expect(Yast::Builtins::Multiset.merge([1, 2], [2, 3])).to eq([1, 2, 2, 3])
      expect(Yast::Builtins::Multiset.merge([1, 2, 2], [2, 2, 3])).to eq([1, 2, 2, 2, 2, 3])
      expect(Yast::Builtins::Multiset.merge([2, 1, 2], [2, 3, 2])).to eq([2, 1, 2, 2, 3, 2])
    end
  end
end
