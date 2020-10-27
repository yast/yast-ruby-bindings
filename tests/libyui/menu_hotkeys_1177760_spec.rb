require_relative "rspec_tmux_tui"

describe "Menu Item" do
  bug = "1177760" # https://bugzilla.suse.com/show_bug.cgi?id=1177760
  around(:each) do |ex|
    @base = "menu_hotkeys_#{bug}"
    @tui = YastTui.new
    @tui.example("MenuBar1") do
      ex.run
    end
  end

  it "has hotkeys in menu items, boo##{bug}" do
    @tui.await(/File.*Edit.*View/)
    @tui.capture_pane_to("#{@base}-1-initial")

    @tui.send_keys "M-V"        # &View
    @tui.capture_pane_to("#{@base}-2-view-menu-activated")

    @tui.send_keys "M-N"        # &Normal
    @tui.capture_pane_to("#{@base}-3-normal-menu-item-activated")

    # the label
    expect(@tui.capture_pane).to include("Last Event")
    # the output
    expect(@tui.capture_pane).to include("view_normal")

    @tui.send_keys "M-Q"        # &Quit
  end
end
