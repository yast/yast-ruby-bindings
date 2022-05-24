#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"
require "yast/y2start_helpers"

describe Yast::Y2StartHelpers do
  subject { described_class }

  describe ".help" do
    it "returns multiline help text" do
      expect(subject.help).to be_a ::String
    end
  end

  describe ".setup_signals" do
    it "setups signal trap" do
      expect(::Signal).to receive(:trap).at_least(:once)

      subject.setup_signals
    end
  end

  describe ".parse_arguments" do
    it "parses passed arguments and returns it as hash" do
      expected_output = {
        generic_options: {},
        client_name: "test",
        client_options: {params: ["abc"]},
        server_name: "UI",
        server_options: ["--geometry", "800x600"]
      }

      arguments = ["test", "--arg", "abc", "UI", "--geometry", "800x600"]
      expect(subject.parse_arguments(arguments)).to eq expected_output
    end

    INVALID_ARGUMENTS = [
      [],
      ["test"],
      ["--bla", "test", "UI"],
      ["test", "--bla", "UI"]
    ]
    it "raises exception if wrong arguments are passed" do
      INVALID_ARGUMENTS.each do |arg|
        expect{subject.parse_arguments(arg)}.to raise_error(RuntimeError)
      end
    end
  end

  describe ".application_title" do
    before do
      stub_const("Yast::UI", double("Yast::UI"))
    end

    context "s390 architecture" do
      before do
        allow(subject).to receive(:is_s390).and_return(true)
      end

      context "is in text mode" do
        it "returns s390 architecture" do
          expect(subject).to receive(:read_values).and_return("2964 = z13 IBM z13")
          expect(Yast::UI).to receive(:TextMode).and_return(true)
          expect(subject.application_title("client_name")).to match(/IBM z13/)
        end
      end

      context "is in QT mode" do
        it "sets environment variable YAST_BANNER" do
          expect(subject).to receive(:read_values).and_return("2964 = z13 IBM z13")
          expect(Yast::UI).to receive(:TextMode).and_return(false)
          expect(subject.application_title("client_name")).not_to match(/IBM z13/)
          expect(ENV["YAST_BANNER"]).to eq("IBM z13")
          # unset YAST_BANNER for further tests
          ENV["YAST_BANNER"] = ""
        end
      end

      context "read_values returns empty string" do
        it "returns client name only" do
          expect(subject).to receive(:read_values).and_return("")
          expect(Yast::UI).to receive(:TextMode).and_return(true)
          expect(subject.application_title("client_name").strip).to eq("YaST2 - client_name")
        end
      end
    end

    context "x86_64 archtecture" do
      before do
        allow(subject).to receive(:is_s390).and_return(false)
        expect(subject).not_to receive(:read_values)
      end

      context "is in text mode" do
        it "returns client name only" do
          expect(subject.application_title("client_name").strip).to eq("YaST2 - client_name")
        end
      end

      context "is in QT mode" do
        it "does not set environment variable YAST_BANNER" do
          expect(subject.application_title("client_name").strip).to eq("YaST2 - client_name")
          expect(ENV["YAST_BANNER"]).to eq("")
        end
      end
    end
  end

  describe ".generate_exit_code" do
    it "returns 0 for nil" do
      expect(subject.generate_exit_code(nil)).to eq 0
    end

    it "returns 0 for true" do
      expect(subject.generate_exit_code(true)).to eq 0
    end

    it "returns 16 for false" do
      expect(subject.generate_exit_code(false)).to eq 16
    end

    it "returns 16 for `:abort`" do
      expect(subject.generate_exit_code(:abort)).to eq 16
    end

    it "returns 16 for `:cancel`" do
      expect(subject.generate_exit_code(:cancel)).to eq 16
    end

    it "returns 0 for other symbols" do
      expect(subject.generate_exit_code(:test)).to eq 0
    end

    it "returns 16+number for number" do
      expect(subject.generate_exit_code(1)).to eq 17
      expect(subject.generate_exit_code(3)).to eq 19
    end
  end

  describe ".redirect_scr" do
    it "opens a new SCR with chroot option" do
      target = "/mnt"
      handle = 42

      allow(Yast::WFM).to receive(:SCRGetDefault)
      expect(Yast::WFM).to receive(:SCROpen).with("chroot=#{target}:scr", false)
        .and_return(handle)
      expect(Yast::WFM).to receive(:SCRSetDefault).with(handle)

      subject.redirect_scr(target)
    end
  end
end
