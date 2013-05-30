require "ycp/term"

module YCP
  module UI

  # Define symbols for the UI
  UI_TERMS = [ :BarGraph, :Bottom, :CheckBox, :ColoredLabel, :ComboBox, :Date,
    :DownloadProgress, :DumbTab, :DummySpecialWidget, :Empty, :Frame, :HBox, :HBoxvHCenter,
    :HMultiProgressMeter, :HSpacing, :HSquash, :HStretch, :HVCenter, :HVSquash,
    :HVStretch, :HWeight, :Heading, :IconButton, :Image, :IntField, :Label, :Left, :LogView,
    :MarginBox, :MenuButton, :MinHeight, :MinSize, :MinWidth, :MultiLineEdit,
    :MultiSelectionBox, :PackageSelector, :PatternSelector, :PartitionSplitter,
    :Password, :PkgSpecial, :ProgressBar, :PushButton, :RadioButton,
    :RadioButtonGroup, :ReplacePoint, :RichText, :Right, :SelectionBox, :Slider, :Table,
    :TextEntry, :Time, :Top, :Tree, :VBox, :VCenter, :VMultiProgressMeter, :VSpacing,
    :VSquash, :VStretch, :VWeight, :Wizard
    ]

   # for each symbol define a util function that will create a term
    UI_TERMS.each do | term_name |
      define_method(term_name) do | *args |
        YCP::Term.new(term_name, *args)
      end
    end
  end
end
