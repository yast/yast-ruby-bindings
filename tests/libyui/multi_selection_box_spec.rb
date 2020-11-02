require_relative "rspec_tmux_tui"

describe "MultiSelectionBox" do
  context "Basics" do
    before(:all) do
      @base = "multi_selection_box_basics"
      @tui = YastTui.new
      @tui.example("MultiSelectionBox-test")
      @tui.await("Select toppings")
      @tui.capture_pane_to("#{@base}-1")
    end

    after(:all) do
      @tui.send_keys "M-C"        # &Close
    end

    describe "Visual appearance" do
      it "Has all the expected items" do
        # the output; //m = match across lines
        expect(@tui.capture_pane).to match(/Cheese.*Tomatoes.*Mushrooms.*Onions.*Salami.*Ham/m)
      end

      it "Visually selects the right items initially" do
        expect(@tui.capture_pane).to include("[x] Cheese", "[x] Tomatoes",
                                             "[ ] Mushrooms", "[ ] Onions", "[ ] Salami", "[ ] Ham")
      end
    end

    describe "Introspection" do
      it "QueryWidget(:SelectedItems) reports the correct items" do
        expect(@tui.capture_pane).to match(/Selected:\s+\[:cheese, :tomatoes\]/)
      end

      it "QueryWidget(:CurrentItem) reports the correct item" do
        expect(@tui.capture_pane).to match(/Current:\s+:cheese/)
      end
    end

    describe "Basic keyboard handling" do
      it "Moving the cursor works" do
        @tui.send_keys "M-S"      # &Select toppings
        @tui.send_keys "Home"     # first item
        @tui.send_keys "Down"
        @tui.send_keys "Down"
        expect(@tui.capture_pane).to match(/Current:\s+:mushrooms/)
        @tui.send_keys "End"        # last item
        expect(@tui.capture_pane).to match(/Current:\s+:ham/)
      end

      it "Selecing an item works visually and in the internal state" do
        @tui.send_keys "M-S"      # &Select toppings
        @tui.send_keys "End"      # last item ("Ham")
        @tui.send_keys "Space"    # select/deselect item
        expect(@tui.capture_pane).to match(/Selected:\s+\[:cheese, :tomatoes\, :ham\]/)
        expect(@tui.capture_pane).to include("[x] Ham")
      end

      it "Deselecting an item works visually and in the internal state" do
        @tui.send_keys "M-S"      # &Select toppings
        @tui.send_keys "Home"     # first item
        @tui.send_keys "Down"     # one item down to "Tomatoes"
        @tui.send_keys "Space"    # select/deselect item
        expect(@tui.capture_pane).to match(/Selected:\s+\[:cheese\, :ham\]/)
        expect(@tui.capture_pane).to include("[ ] Tomatoes")
      end
    end

    describe "Exchanging content" do
      it "Replacing all items works" do
        expect(@tui.capture_pane).to include("[ ] Vegetarian")
        @tui.send_keys "M-V"      # &Vegetarian
        @tui.send_keys "Space"    # toggle combo box
        @tui.await(/Current:.*:mushrooms/)
        expect(@tui.capture_pane).to include("[x] Vegetarian")
        expect(@tui.capture_pane).not_to include("Salami")
        expect(@tui.capture_pane).not_to include("Ham")

        @tui.send_keys "M-V"      # &Vegetarian
        @tui.send_keys "Space"    # toggle combo box
        @tui.await("Salami")
        expect(@tui.capture_pane).to include("[ ] Vegetarian")
        expect(@tui.capture_pane).to include("Salami")
        expect(@tui.capture_pane).to include("Ham")
      end
    end
  end

  context "Known fixed bugs" do

    around(:each) do |ex|
      @base = "multi_selection_box"
      @tui = YastTui.new
      @tui.example("MultiSelectionBox-test") do
        @tui.await("Select toppings")
        ex.run
        @tui.send_keys "M-C"        # &Close
      end
    end

    it "bsc#1177985: QueryWidget(:SelectedItems) does not return nil after replacing the items" do
      @bug = "1177985"       # https://bugzilla.suse.com/show_bug.cgi?id=1177985

      @tui.send_keys "M-V"      # &Vegetarian
      @tui.send_keys "Space"    # toggle combo box (this will replace all items)
      @tui.await(/Current:.*:mushrooms/)
      @tui.capture_pane_to("#{@base}-#{@bug}")

      expect(@tui.capture_pane).to match(/Selected:.*:cheese, :tomatoes/)
    end
  end
end
