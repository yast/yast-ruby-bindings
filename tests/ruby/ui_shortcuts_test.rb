$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/ui_shortcuts"

class UIShortcutsTest < YCP::TestCase
  include YCP::UIShortcuts

  def test_shortcuts
    assert_equal YCP::Term.new(:HBox), HBox()
    assert_equal YCP::Term.new(:HBox, "test"), HBox("test")
  end
end
