#! /usr/bin/env rspec

require_relative "rspec_tmux_tui"

# check that the test client is running and displaying the initial dialog
def check_dialog
  screenshot = @tui.capture_pane
  # the buttons are there
  expect(screenshot).to include("[Help]")
  expect(screenshot).to include("[Close]")
end

describe "Help text" do
  around(:each) do |example|
    y2start = "ruby -r #{__dir__}/../test_helper #{__dir__}/../../src/y2start/y2start"
    @base = "empty_help"
    log_dir = "#{__dir__}/log"
    Dir.mkdir log_dir if !File.exist?(log_dir)
    @log_base = "#{log_dir}/#{@base}"
    @tui = TmuxTui.new
    @tui.new_session "#{y2start} #{__dir__}/#{@base}.rb ncurses" do
      example.run
    end
  end

  # check that the empty help text is properly displayed (bsc#972548)
  it "displays empty popup for empty help text" do
    @tui.await("[Help]")
    check_dialog
    @tui.capture_pane_to("#{@log_base}-1-initial")

    # show help by pressing F1
    @tui.send_keys "F1"
    @tui.await("[OK]")
    @tui.capture_pane_to("#{@log_base}-2-help-activated")

    # close the help popup
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@log_base}-3-help-closed")
    @tui.await("[Help]")
    check_dialog

    # close the application (&Close)
    @tui.send_keys "M-C"
  end
end
