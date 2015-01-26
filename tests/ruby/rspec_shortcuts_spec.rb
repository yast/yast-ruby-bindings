#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec"

describe Yast::RSpec::Shortcuts do
  describe "#path" do
    it "returns the expected Yast::Path object" do
      expect(path(".target.dir")).to eq(Yast::Path.new(".target.dir"))
    end
  end
end
