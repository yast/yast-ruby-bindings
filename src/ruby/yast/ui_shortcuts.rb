require "yast/term"

module Yast
  # Module that provides shortcuts for known UI terms, so UI can be constructed in nice way.
  module UIShortcuts
    # Define symbols for the UI
    # See https://github.com/libyui/libyui/blob/master/src/YUISymbols.h
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
      :CustomStatusItemSelector,
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
      :MenuBar,
      :MenuButton,
      :MinHeight,
      :MinSize,
      :MinWidth,
      :MultiItemSelector,
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
      :SingleItemSelector,
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
      :icon,
      :id,
      :item,
      :header,
      :menu,
      :opt
    ].freeze

    # for each symbol define a util function that will create a term
    UI_TERMS.each do |term_name|
      method_name = term_name.to_s
      method_name[0] = method_name[0].upcase
      define_method(method_name.to_sym) do |*args|
        Yast::Term.new(term_name, *args)
      end
    end
  end
end
