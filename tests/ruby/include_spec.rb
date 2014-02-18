#!/usr/bin/env rspec

require_relative "test_helper_rspec"

require "yast"

module Yast
  describe ".include" do
    it "does not loop endlessly on cyclic includes" do
      expect { Yast.include(Yast, "cyclic_yin.rb") }.not_to raise_error
    end
  end
end
