require "yast/term"

module Yast
  module UIShortcuts

  # Define symbols for the UI
  UI_TERMS = [
    :BarGraph,
    :BusyIndicator,
    :Bottom,
    :ButtonBox,
    :Cell,
    :Center,
    :CheckBox,
    :CheckBoxFrame,
    :ColoredLabel, 
    :ComboBox,
    :DateField,
    :DownloadProgress,
    :DumbTab,
    :Dummy,
    :DummySpecialWidget,
    :Empty,
    :Frame,
    :HBox,
    :HCenter,
    :HMultiProgressMeter,
    :HSpacing,
    :HSquash,
    :HStretch,
    :HVCenter,
    :HVSquash,
    :HVStretch,
    :HWeight,
    :Heading,
    :IconButton,
    :Image,
    :InputField,
    :IntField,
    :Label,
    :Left,
    :LogView,
    :MarginBox,
    :MenuButton,
    :MinHeight,
    :MinSize,
    :MinWidth,
    :MultiLineEdit,
    :MultiSelectionBox,
    :PackageSelector,
    :PatternSelector,
    :PartitionSplitter,
    :Password,
    :PkgSpecial,
    :ProgressBar,
    :PushButton,
    :RadioButton,
    :RadioButtonGroup,
    :ReplacePoint,
    :RichText,
    :Right,
    :SelectionBox,
    :Slider,
    :Table,
    :TextEntry,
    :TimeField,
    :TimezoneSelector,
    :Top,
    :Tree,
    :VBox,
    :VCenter,
    :VMultiProgressMeter,
    :VSpacing,
    :VSquash,
    :VStretch,
    :VWeight,
    :Wizard,
    # special ones that will be upper cased
    :id,
    :item,
    :header,
    :opt,
    :Time, #FIXME obsolete remove
    :Date, #FIXME obsolete remove
    ]

   # for each symbol define a util function that will create a term
    UI_TERMS.each do | term_name |
      method_name = term_name.to_s
      method_name[0] = method_name[0].upcase
      define_method(method_name.to_sym) do | *args |
        Yast::Term.new(term_name, *args)
      end
    end
  end
end