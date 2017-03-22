#!/usr/bin/env rspec

require_relative "test_helper"

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

      it "produces no warning (about redefined constants)" do
        # require_relative does not work in -e
        helper = $LOADED_FEATURES.grep(/test_helper/).first
        script = <<-EOS
          load '#{helper}'
          require 'yast'
          Yast::WFM.CallFunction('test_client')
          Yast::WFM.CallFunction('test_client')
        EOS
        stdout_stderr = `ruby -e "#{script}" 2>&1`
        expect(stdout_stderr).to eq ""
      end

      it "raises error if first parameter is not string" do
        expect { WFM.CallFunction(:test_client) }.to raise_error(ArgumentError)
      end

      it "raises error if second parameter is not array" do
        expect { WFM.CallFunction("test_client", nil) }.to raise_error(ArgumentError)
      end
    end

    describe ".call" do
      it "is aliased to CallFunction" do
        expect(WFM.call("test_client")).to eq 15
      end
    end

    describe ".scr_chrooted?" do
      it "returns false for local scr" do
        expect(WFM.scr_chrooted?).to eq false
      end

      it "returns true for scr in chroot" do
        old_handle = WFM.SCRGetDefault
        handle = WFM.SCROpen("chroot=/tmp:scr", false)
        WFM.SCRSetDefault(handle)

        expect(WFM.scr_chrooted?).to eq true

        WFM.SCRSetDefault(old_handle)
      end
    end

    describe ".scr_root" do
      it "returns root path of scr" do
        expect(WFM.scr_root).to eq "/"

        old_handle = WFM.SCRGetDefault
        handle = WFM.SCROpen("chroot=/tmp:scr", false)
        WFM.SCRSetDefault(handle)

        expect(WFM.scr_root).to eq "/tmp"

        WFM.SCRSetDefault(old_handle)
      end
    end
  end
end
