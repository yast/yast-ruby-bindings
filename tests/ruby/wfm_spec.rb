#!/usr/bin/env rspec

require_relative "test_helper_rspec"

require "yast"

module Yast
  describe WFM do
    describe ".CallFunction" do
      it "calls yast client via component system returning its value" do
        expect(WFM.CallFunction("test_client")).to eq 15
      end

      it "always properly initialize client (BNC#861529)" do
        expect(WFM.CallFunction("test_client")).to eq 15
        expect(WFM.CallFunction("test_client")).to eq 15
      end
    end
  end
end
