#!/usr/sbin/yast
module Yast
  class TableCellClient < Client
    def main
      Yast.import "UI"

      # notice that neither the ids nor the values are sorted here
      contents = [
	Item(Id("id-zzz-1"), "name-bbb", "value-bbb"),
        Item(Id("id-yyy-2"), "name-ccc", "value-ccc"),
        Item(Id("id-xxx-3"), "name-aaa", "value-aaa"),
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
          PushButton(Id(:cancel), "&Close")
        )
      )

      while UI.UserInput != :cancel
        current_item_id = UI.QueryWidget(Id(:table), :CurrentItem)
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
