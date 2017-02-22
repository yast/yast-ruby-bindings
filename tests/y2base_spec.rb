#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"
require "yast/y2base"

describe Yast::Y2Base do
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
        generic_options: { help: true },
        client_name: "test",
        client_options: {params: ["abc"]},
        server_name: "UI",
        server_options: ["--geometry", "800x600"]
      }

      arguments = ["--help", "test", "--arg", "abc", "UI", "--geometry", "800x600"]
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
end
