#! /usr/bin/env ruby

require "yast"
require "yast/ui_shortcuts"
include Yast::UIShortcuts

Yast.ui_component = ARGV[0] || "ncurses" if Yast.ui_component == ""

Yast.import "UI"
Yast::UI.OpenUI

# trivial UI, just [Help] and [Close] buttons
Yast::UI.OpenDialog(
  Opt(:defaultsize),
  HBox(
    HStretch(),
    PushButton(Id(:help), Opt(:key_F1, :helpButton), "&Help"),
    HSpacing(3),
    PushButton(Id(:close), Opt(:key_F10, :default), "&Close"),
    HStretch()
  )
)

ui = Yast::UI.UserInput

Yast::UI.CloseDialog
Yast::UI.CloseUI

puts ui.inspect
