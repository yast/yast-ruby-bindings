#! /usr/bin/env rspec

require_relative "../test_helper"
require "yast/ui_shortcuts"

Yast.import "UI"

def std_puts(message)
  $stdout.puts "stdout: #{message}"
  $stderr.puts "stderr: #{message}"
end

# Regression test for the fix of bnc#943757 implemented
# in libyui-ncurses 2.47.3
describe "streams redirection in libyui-ncurses" do
  include Yast::UIShortcuts

  around do |example|
    Yast.ui_component = "ncurses"
    Yast::UI.OpenUI
    example.run
    Yast::UI.CloseUI

    # Having an expectation in the around block looks weird, but using around
    # to execute OpenUI/CloseUI was needed to make the bug pop up.
    #
    # In addition to not crashing, these messages should be displayed when
    # running RSpec, not sure if it's possible to check that.
    expect { std_puts "tty is free again" }.to_not raise_error
  end

  it "does not fall apart when stderr is used" do
    Yast::UI.OpenDialog(PushButton("Hello, World!"))
    expect { std_puts "NCurses is using the tty" }.to_not raise_error
    Yast::UI.CloseDialog
  end
end
