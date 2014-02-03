require_relative "test_helper_test_unit"

require "yast/ui_shortcuts"

class UIShortcutsTest < Yast::TestCase
  include Yast::UIShortcuts

  def test_shortcuts
    assert_equal Yast::Term.new(:HBox), HBox()
    assert_equal Yast::Term.new(:HBox, "test"), HBox("test")
  end
end
