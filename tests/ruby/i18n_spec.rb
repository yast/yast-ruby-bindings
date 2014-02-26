#!/usr/bin/env rspec

require_relative "test_helper_rspec"

require "yast"

include Yast::I18n

module Yast
  describe I18n do

    describe ".N_" do
      it "returns the original parameter" do
        input = "INPUT TEST"
        expect(N_(input)).to be input
      end
    end

    describe ".Nn_" do
      it "returns the original parameters" do
        singular = "singular"
        plural = "plural"
        count = 42

        expect(Nn_(singular, plural, count)).to eq [singular, plural, count]
      end
    end

  end
end
