#! /usr/bin/env rspec

require_relative "../test_helper"

require "yast"

# remember the current locale
old_locale = ENV["LC_ALL"]

class TranslationExample
  include Yast::I18n

  def initialize
    textdomain "example"
  end

  def translation_simple
    _("Example")
  end

  def translation_plural(n)
    format(n_("%s Example", "%s Examples", n), n)
  end

  def translation_mark
    N_("Example")
  end

  def translation_mark_plural(n)
    Nn_("%s Example", "%s Examples", n)
  end
end

describe "translations in YaST" do
  subject { TranslationExample.new }

  before(:all) do
    # set the Czech language for all tests
    ENV["LC_ALL"] = "cs_CZ.UTF-8"
  end

  after(:all) do
    # revert the original locale at the end
    ENV["LC_ALL"] = old_locale
  end

  before do
    # override the default path with translations
    stub_const("Yast::I18n::LOCALE_DIR", File.expand_path("../locale", __FILE__))
  end

  it "translates string using _()" do
    expect(subject.translation_simple).to eq("Příklad")
  end

  it "translates plural string using n_() with 0 value" do
    expect(subject.translation_plural(0)).to eq("0 Příkladů")
  end

  it "translates plural string using n_() with 1 value" do
    expect(subject.translation_plural(1)).to eq("1 Příklad")
  end

  it "translates plural string using n_() with 2 value" do
    expect(subject.translation_plural(2)).to eq("2 Příklady")
  end

  it "translates plural string using n_() with 5 value" do
    expect(subject.translation_plural(5)).to eq("5 Příkladů")
  end

  it "does not translate string using N_()" do
    expect(subject.translation_mark).to eq("Example")
  end

  it "does not translate string using Nn_()" do
    expect(subject.translation_mark_plural(0)).to eq(["%s Example", "%s Examples", 0])
  end
end
