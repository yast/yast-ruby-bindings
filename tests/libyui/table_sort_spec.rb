require_relative "rspec_tmux_tui"

log_dir = "#{__dir__}/log"
Dir.mkdir log_dir if !File.exist?(log_dir)

describe "Table" do
  context "when it sorts the items," do
    around(:each) do |ex|
      y2start = "ruby -r #{__dir__}/../test_helper #{__dir__}/../../src/y2start/y2start"
      @base = "table_sort"
      @tui = TmuxTui.new
      @tui.new_session "#{y2start} #{__dir__}/#{@base}.rb -a change-current-item ncurses" do
        ex.run
      end
    end

    bug = "1165388" # https://bugzilla.suse.com/show_bug.cgi?id=1165388
    it "ChangeWidget(_, Cell(row, col)) changes the correct cell, boo##{bug}" do
      base = "#{log_dir}/#{@base}_cell"
      @tui.await(/Table sorting test/)
      @tui.capture_pane_to("#{base}-1-initial")

      @tui.send_keys "Home"     # go to first table row
      @tui.capture_pane_to("#{base}-2-first-row-selected")

      @tui.send_keys "Enter"    # activate first table row
      @tui.capture_pane_to("#{base}-3-first-row-activated")

      expect(@tui.capture_pane).to match(/name-aaa.VALUE-AAA/)

      @tui.send_keys "M-C"      # &Close
    end

    bug = "1177145" # https://bugzilla.suse.com/show_bug.cgi?id=1177145
    it "ChangeWidget(_, :CurrentItem) activates the correct line, boo##{bug}" do
      base = "#{log_dir}/#{@base}_current_item"
      @tui.await(/Table sorting test/)
      @tui.capture_pane_to("#{base}-1-ccc-selected")
      # the UI code performs a
      #   UI.ChangeWidget(Id(:table), :CurrentItem, "id-yyy-2-ccc")
      # then
      #   UI.QueryWidget(Id(:table), :CurrentItem)
      @tui.send_keys "Enter"    # activate the current item to produce an event
      expect(@tui.capture_pane).to match(/Current Item: "id-yyy-2-ccc"/)

      @tui.send_keys "M-C"      # &Close
    end
  end
end
