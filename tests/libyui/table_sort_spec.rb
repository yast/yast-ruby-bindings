require_relative "rspec_tmux_tui"

describe "Table" do
  context "when it sorts the items," do
    around(:each) do |ex|
      yast_ncurses = "#{__dir__}/yast_ncurses"
      @base = "table_sort"
      @tui = TmuxTui.new_session "#{yast_ncurses} #{__dir__}/#{@base}.rb change-current-item"
      ex.run
      @tui.kill_session if @tui.has_session?
    end

    bug = "1165388"
    it "ChangeWidget(_, Cell(row, col)) changes the correct cell, boo##{bug}" do
      base = @base + "_cell"
      @tui.await(/Table sorting test/)
      @tui.capture_pane_to("#{base}-1-initial")

      @tui.send_keys "Home"     # go to first table row
      @tui.capture_pane_to("#{base}-2-first-row-selected")

      @tui.send_keys "Enter"    # activate first table row
      @tui.capture_pane_to("#{base}-3-first-row-activated")

      expect(@tui.capture_pane).to match(/name-aaa.VALUE-AAA/)

      @tui.send_keys "M-C"      # &Close
    end

    bug = "1177145"
    it "ChangeWidget(_, :CurrentItem) activates the correct line, boo##{bug}" do
      skip "not fixed yet"

      base = @base + "_current_item"
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
