require_relative "rspec_tmux_tui"

describe "MultiSelectionBox" do
  bug = "1177760" # https://bugzilla.suse.com/show_bug.cgi?id=1177982

  around(:each) do |ex|
    @base = "multi_selection_box_#{bug}"
    @tui = YastTui.new
    @tui.example("MultiSelectionBox3") do
      ex.run
    end
  end

  it "ChangeWidget(_, :SelectedItems, _) works, boo##{bug}" do
    @tui.await("Select pizza toppings")
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-S"        # &Select pizza toppings
    @tui.send_keys "Home"       # first box item
    @tui.capture_pane_to("#{@base}-2-box-activated")

    @tui.send_keys "Space"
    @tui.send_keys "Down"
    @tui.send_keys "Space"
    @tui.capture_pane_to("#{@base}-3-two-items-selected")

    @tui.send_keys "M-O"        # &OK
    @tui.capture_pane_to("#{@base}-4-report")

    # the label
    @tui.await("Your pizza will come with")
    # the output; //m = match across lines
    expect(@tui.capture_pane).to match(/cheese.*tomatoes.*onions.*sausage/m)

    @tui.send_keys "M-O"        # &OK
  end
end
