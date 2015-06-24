#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"
require "yast/core_ext"

describe Yast::CoreExt::AnsiString do
  describe "#remove_ansi_sequences" do
    context "using the AnsiString refinement" do
      using Yast::CoreExt::AnsiString

      let(:string) {
        file = File.join(File.dirname(__FILE__), "data", filename)
        File.open(file, "rb").read
      }
      let(:result) { " Cyan  Bold\n Pink  Normal\n" }

      context "when the string contains colors" do
        let(:filename) { "ansi_colors.txt" }

        it "removes the ANSI codes" do
          string.remove_ansi_sequences
          expect(string).to eq result
        end
      end

      context "when the string contains cursor movements" do
        let(:filename) { "ansi_cursor.txt" }

        it "removes the ANSI codes" do
          string.remove_ansi_sequences
          expect(string).to eq result
        end
      end

      context "when the string contains cursor movements and colors" do
        let(:filename) { "ansi_both.txt" }

        it "removes the ANSI codes" do
          string.remove_ansi_sequences
          expect(string).to eq result
        end
      end

      context "when the string contains no ANSI codes" do
        let(:string) { "clean" }

        it "does nothing" do
          string.remove_ansi_sequences
          expect(string).to eq "clean"
        end
      end

      context "when the string is frozen" do
        let(:string) { "clean".freeze }

        it "raises an exception" do
          expect { string.remove_ansi_sequences }
            .to raise_error(RuntimeError, /frozen String/)
        end
      end
    end

    context "using the AnsiString refinement" do
      it "is not defined" do
        expect { "a string".remove_ansi_sequences }
          .to raise_error(NoMethodError, /remove_ansi_sequences/)
      end
    end
  end
end
