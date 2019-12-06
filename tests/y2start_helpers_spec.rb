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

end
