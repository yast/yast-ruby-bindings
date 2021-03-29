#! /usr/bin/env ruby
# typed: false

require_relative "../test_helper"
require "yast"

if Yast.ui_component == ""
  Yast.ui_component = ARGV[0] || "ncurses"
end

module Yast
  class TableCellClient < Client
    def main
      Yast.import "UI"

      # notice that neither the ids nor the values are sorted here
      contents = [
        Item(Id("id-zzz-1-bbb"), "name-bbb", "value-bbb"),
        Item(Id("id-yyy-2-ccc"), "name-ccc", "value-ccc"),
        Item(Id("id-xxx-3-aaa"), "name-aaa", "value-aaa"),
      ]
      keep_sorting = WFM.Args()[0] == "no-sort"
      opts = keep_sorting ? Opt(:keepSorting, :notify) : Opt(:notify)
      UI.OpenDialog(
        VBox(
          Label("Table sorting test"),
          MinSize(
            25, 8,
            Table(Id(:table), opts, Header("Name", "Value"), contents)
          ),
          Label("Enter/Double-click any item to uppercase the value"),
          HBox(
            HSquash(Label("Current Item: ")),
            Label(Id(:current_item), Opt(:outputField, :hstretch), "...")
          ),
          PushButton(Id(:cancel), "&Close")
        )
      )

      if WFM.Args()[0] == "change-current-item"
        # test boo#1177145, wrong item is selected
        UI.ChangeWidget(Id(:table), :CurrentItem, "id-yyy-2-ccc")
        current_item_id = UI.QueryWidget(Id(:table), :CurrentItem)
        UI.ChangeWidget(Id(:current_item), :Value, current_item_id.inspect)
      end

      while UI.UserInput != :cancel
        current_item_id = UI.QueryWidget(Id(:table), :CurrentItem)
        UI.ChangeWidget(Id(:current_item), :Value, current_item_id.inspect)

        value = UI.QueryWidget(:table, Cell(current_item_id, 1))
        UI.ChangeWidget(Id(:table), Cell(current_item_id, 1), value.upcase)
      end
      items = UI.QueryWidget(:table, :Items)
      Builtins.y2milestone("Items: %1", items)

      UI.CloseDialog
      nil
    end
  end
end

Yast::TableCellClient.new.main
