#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec"

describe Yast::RSpec::Matchers do
  describe "#path_matching" do
    it "matches if the path is identical" do
      path = Yast::Path.new(".etc")
      expect(path).to receive(:+).with(path_matching('\.fstab'))
        .and_return "success"

      expect(path + path(".fstab")).to eq "success"
    end

    it "does not match if the argument is not a YaST Path" do
      path = Yast::Path.new(".etc")
      expect(path).to_not receive(:+).with(path_matching('\.fstab'))

      path + ".fstab"
    end

    it "matches a simple regular expression" do
      expect(Yast::SCR).to receive(:Read)
        .with(path_matching(/target.*ir$/)).and_return "success"

      expect(Yast::SCR.Read(path(".target.dir"))).to eq "success"
    end

    it "does not match if the regexp does not match" do
      expect(Yast::SCR).to_not receive(:Read)
        .with(path_matching(/target.*ir$/))

      Yast::SCR.Read(path(".etc"))
    end
  end
end
