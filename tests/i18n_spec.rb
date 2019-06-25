#!/usr/bin/env rspec
# typed: false

require_relative "test_helper"

require "yast"



describe Yast do
  describe Yast::I18n do
    include Yast::I18n
    extend Yast::I18n

    let(:translated) { "translated".freeze }
    let(:singular) { "untranslated".freeze }
    let(:plural) { "plural".freeze }

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
        count = 42

        expect(Nn_(singular, plural, count)).to eq [singular, plural, count]
      end
    end

    describe "._" do
      before do
        allow(File).to receive(:exist?).with(Yast::I18n::LOCALE_DIR)
          .and_return(true)
        textdomain("base")
      end

      it "returns the translated string" do
        allow(FastGettext).to receive(:key_exist?).and_return(true)
        expect(Yast::Translation).to receive(:_).with(singular)
          .and_return(translated)
        expect(_(singular)).to eq(translated)
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
          expect(_(singular)).to eq(singular)
        end

        it "logs a warning message" do
          expect(Yast).to receive(:y2warning).at_least(1)
            .with(/File not found/)
          _(singular)
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
          .with(singular, plural, 1).and_return(translated)
        expect(n_(singular, plural, 1)).to eq(translated)
      end

      context "when FastGettext throws an Errno::ENOENT exception" do
        before do
          allow(FastGettext).to receive(:cached_plural_find)
            .and_raise(Errno::ENOENT)
        end

        it "returns the singular untranslated string if num is 1" do
          expect(n_(singular, plural, 1)).to eq(singular)
        end

        it "returns the plural untranslated string if num > 1" do
          expect(n_(singular, plural, 2)).to eq(plural)
        end

        it "logs a warning message" do
          expect(Yast).to receive(:y2warning).at_least(1)
            .with(/File not found/)
          expect(n_(singular, plural, 1)).to eq(singular)
        end
      end
    end
  end
end
