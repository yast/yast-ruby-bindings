#!/usr/bin/env rspec
# typed: false
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/ui_shortcuts"

describe "UIShortcutsTest" do
  include Yast::UIShortcuts

  it "tests shortcuts" do
    expect(HBox()).to eq(Yast::Term.new(:HBox))
    expect(HBox("test")).to eq(Yast::Term.new(:HBox, "test"))
  end
end
