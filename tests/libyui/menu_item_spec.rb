require_relative "rspec_tmux_tui"

describe "Menu Item" do
  before(:all) do
    @base = "multi_selection_box_basics"
    @tui = YastTui.new
    @tui.example("MenuBar-shortcuts-test")
    @tui.await(/File.*Edit.*View/)
  end

  after(:all) do
    @tui.send_keys "M-Q"        # &Quit
  end

  bug = "1177760" # https://bugzilla.suse.com/show_bug.cgi?id=1177760
  it "has shortcuts in menu items, boo##{bug}" do
    @base = "menu_shortcuts_#{bug}"
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-V"        # &View menu
    @tui.capture_pane_to("#{@base}-2-view-menu-activated")

    @tui.send_keys "M-N"        # &Normal
    @tui.capture_pane_to("#{@base}-3-normal-menu-item-activated")

    # the label
    expect(@tui.capture_pane).to include("Last Event")
    # the output
    expect(@tui.capture_pane).to include("view_normal")
  end

  bug = nil
  it "menu shortcuts have higher priority than button shortcuts" do
    @base = "menu_shortcuts_prio"
    @tui.capture_pane_to("#{@base}-1-initial")

    # No extra buttons: The "&View" menu has shortcut "V"
    expect(@tui.capture_pane).not_to include("[File]", "[Edit]", "[View]")
    @tui.send_keys "M-V"        # &View menu
    @tui.capture_pane_to("#{@base}-2-view-menu-activated")
    expect(@tui.capture_pane).to include("Normal", "Compact", "Detailed", "Zoom")
    @tui.send_keys "Down"
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-3-view-compact-activated")
    expect(@tui.capture_pane).to include("Last Event:", "view_compact")

    # Toggle extra buttons
    @tui.send_keys "M-B"        # Extra &Buttons
    @tui.capture_pane_to("#{@base}-4-extra-buttons-activated")
    expect(@tui.capture_pane).to include("[File]", "[Edit]", "[View]")

    # With extra buttons: The "&View" menu still has shortcut "V"
    @tui.send_keys "M-V"        # &View menu
    @tui.capture_pane_to("#{@base}-5-view-menu-activated")
    expect(@tui.capture_pane).to include("Normal", "Compact", "Detailed", "Zoom")
    @tui.send_keys "Down"
    @tui.send_keys "Down"
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-6-view-detailed-activated")
    expect(@tui.capture_pane).to include("Last Event:", "view_detailed")

    # And the "View" button has "W"
    @tui.send_keys "M-W"        # Vie&w button
    @tui.capture_pane_to("#{@base}-7-view-button-activated")
    expect(@tui.capture_pane).to include("Last Event:", "b_view")
  end

  bug = "1178394" # https://bugzilla.suse.com/show_bug.cgi?id=1178394
  it "remains disabled after shortcuts are recomputed" do
    @base = "menu_disabled_#{bug}"
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-E"        # &Edit menu
    @tui.capture_pane_to("#{@base}-2-edit-menu-activated")

    # select the 1st available item; it is Copy because Cut is disabled
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-3-copy-item-activated")
    expect(@tui.capture_pane).to include("Last Event:", "copy")

    @tui.send_keys "M-B"        # Extra &Buttons
    @tui.capture_pane_to("#{@base}-4-extra-buttons-activated")

    # Enabling the extra buttons calls UI.ReplaceWidget() which triggers
    # checking keyboard shortcuts which causes the menu tree to be rebuilt.
    # The bug was that this did not honor the item enabled/disabled state.

    @tui.send_keys "M-E"        # &Edit menu
    @tui.capture_pane_to("#{@base}-5-edit-menu-activated")

    # select the 1st available item; it is Copy because Cut is disabled
    @tui.send_keys "Enter"
    @tui.capture_pane_to("#{@base}-6-copy-item-activated")
    expect(@tui.capture_pane).to include("Last Event:", "copy")
  end
end
