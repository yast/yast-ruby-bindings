require_relative "rspec_tmux_tui"

describe "Menu Item" do
  around(:each) do |ex|
    @tui = YastTui.new
    @tui.example("MenuBar-shortcuts-test") do
      ex.run
    end
  end

  bug = "1177760" # https://bugzilla.suse.com/show_bug.cgi?id=1177760
  it "has hotkeys in menu items, boo##{bug}" do
    @base = "menu_hotkeys_#{bug}"
    @tui.await(/File.*Edit.*View/)
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-V"        # &View menu
    @tui.capture_pane_to("#{@base}-2-view-menu-activated")

    @tui.send_keys "M-N"        # &Normal
    @tui.capture_pane_to("#{@base}-3-normal-menu-item-activated")

    # the label
    expect(@tui.capture_pane).to include("Last Event")
    # the output
    expect(@tui.capture_pane).to include("view_normal")

    @tui.send_keys "M-Q"        # &Quit
  end

  bug = "1178394" # https://bugzilla.suse.com/show_bug.cgi?id=1178394
  it "remains disabled after hotkeys are recomputed" do
    @base = "menu_disabled_#{bug}"
    @tui.await(/File.*Edit.*View/)
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-E"        # &Edit menu
    @tui.capture_pane_to("#{@base}-2-edit-menu-activated")

    # select the 1st available item; it is Copy because Cut is disabled
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-3-copy-item-activated")
    expect(@tui.capture_pane).to include("Last Event:", "copy")

    @tui.send_keys "M-E"        # Extra &Buttons
    @tui.capture_pane_to("#{@base}-4-extra-buttons-activated")

    # Enabling the extra buttons calls UI.ReplaceWidget() which triggers
    # checking keyboard shortcuts which causes the menu tree to be rebuilt.
    # The bug was that this did not honor the item enabled/disabled state.

    @tui.send_keys "M-T"        # &Edit menu
    @tui.capture_pane_to("#{@base}-5-edit-menu-activated")

    # select the 1st available item; it is Copy because Cut is disabled
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-6-copy-item-activated")
    expect(@tui.capture_pane).to include("Last Event:", "copy")

    @tui.send_keys "M-Q"        # &Quit
  end
end
