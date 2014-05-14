#!/usr/bin/env rspec
require_relative "test_helper_rspec"

require "yast/ui_shortcuts"

describe "UIShortcutsTest" do
  include Yast::UIShortcuts

  it "tests shortcuts" do
    expect(HBox()).to eq(Yast::Term.new(:HBox))
    expect(HBox("test")).to eq(Yast::Term.new(:HBox, "test"))
  end
end
