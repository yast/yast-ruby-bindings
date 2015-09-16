#! /usr/bin/env rspec

require_relative "test_helper"
require "yast/ui_shortcuts"

Yast.import "UI"

# We do not have a proper ncurses in travis at the moment
if !ENV["TRAVIS"]
  def std_puts(message)
    $stdout.puts "stdout: #{message}"
    $stderr.puts "stderr: #{message}"
  end

  # Regression test for the fix of bnc#943757 implemented
  # in libyui-ncurses 2.47.3
  describe "streams redirection in libyui-ncurses" do
    include Yast::UIShortcuts

    before do
      Yast.ui_component = "ncurses"
      Yast::UI.OpenUI
    end

    after do
      Yast::UI.CloseUI

      # Having an expectation in the after block looks weird, but using
      # before/after to execute OpenUI/CloseUI was needed to make the bug popup
      #
      # In addition to not crashing, these messages should be displayed when
      # running RSpec, not sure if it's possible to check that
      expect { std_puts "tty is free again" }.to_not raise_error
    end

    it "does not fall apart when stderr is used" do
      Yast::UI.OpenDialog(PushButton("Hello, World!"))
      expect { std_puts "NCurses is using the tty" }.to_not raise_error
      Yast::UI.CloseDialog
    end
  end
end
