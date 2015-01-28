#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec"

describe Yast::RSpec::Shortcuts do
  describe "#path" do
    it "returns the expected Yast::Path object" do
      expect(path(".target.dir")).to eq(Yast::Path.new(".target.dir"))
    end
  end

  describe "#term" do
    it "returns the expected Yast::Term object" do
      expect(term(:ButtonBox)).to eq(Yast::Term.new(:ButtonBox))
    end
  end

  it "include Yast::UIShortcuts" do
    expect(ButtonBox()).to eq(Yast::Term.new(:ButtonBox))
  end
end
