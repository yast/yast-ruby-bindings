#!/usr/bin/env rspec

require_relative "test_helper"

require "yast"

include Yast::I18n

module Yast
  describe I18n do

    before do
      # do not read the real translations from the system
      allow(FastGettext).to receive(:add_text_domain)
    end

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

    describe "._" do
      TRANSLATED = "translated".freeze
      SINGULAR = "untranslated".freeze
      PLURAL = "plural".freeze

      before do
        allow(File).to receive(:exist?).with(Yast::I18n::LOCALE_DIR)
          .and_return(true)
        textdomain("base")
      end

      it "returns the translated string" do
        allow(FastGettext).to receive(:key_exist?).and_return(true)
        expect(Yast::Translation).to receive(:_).with(SINGULAR)
          .and_return(TRANSLATED)
        expect(_(SINGULAR)).to eq(TRANSLATED)
      end

      context "translation is not found" do
        it "returns a frozen string if the translation is not found" do
          allow(FastGettext).to receive(:key_exist?).and_return(false)
          expect(_("foo")).to be_frozen
        end

        it "freezes the passed argument string if the translation is not found" do
          allow(FastGettext).to receive(:key_exist?).and_return(false)
          text = "foo"
          _(text)
          expect(text).to be_frozen
        end
      end

      context "when FastGettext throws an Errno::ENOENT exception" do
        before do
          allow(FastGettext).to receive(:key_exist?)
            .and_raise(Errno::ENOENT)
        end

        it "returns the untranslated string" do
          expect(_(SINGULAR)).to eq(SINGULAR)
        end

        it "logs a warning message" do
          expect(Yast).to receive(:y2warning).at_least(1)
            .with(/File not found/)
          _(SINGULAR)
        end
      end
    end

    describe ".n_" do
      before do
        allow(File).to receive(:exist?).with(Yast::I18n::LOCALE_DIR)
          .and_return(true)
        textdomain("base")
      end

      it "returns the translated string" do
        allow(FastGettext).to receive(:cached_plural_find)
          .and_return(true)
        expect(Yast::Translation).to receive(:n_)
          .with(SINGULAR, PLURAL, 1).and_return(TRANSLATED)
        expect(n_(SINGULAR, PLURAL, 1)).to eq(TRANSLATED)
      end

      context "when FastGettext throws an Errno::ENOENT exception" do
        before do
          allow(FastGettext).to receive(:cached_plural_find)
            .and_raise(Errno::ENOENT)
        end

        it "returns the singular untranslated string if num is 1" do
          expect(n_(SINGULAR, PLURAL, 1)).to eq(SINGULAR)
        end

        it "returns the plural untranslated string if num > 1" do
          expect(n_(SINGULAR, PLURAL, 2)).to eq(PLURAL)
        end

        it "logs a warning message" do
          expect(Yast).to receive(:y2warning).at_least(1)
            .with(/File not found/)
          expect(n_(SINGULAR, PLURAL, 1)).to eq(SINGULAR)
        end
      end
    end
  end
end
