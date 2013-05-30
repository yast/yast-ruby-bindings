$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/ui"

class UITest < YCP::TestCase
  include YCP::UI

  def test_shortcuts
    assert_equal YCP::Term.new(:HBox), HBox()
    assert_equal YCP::Term.new(:HBox, "test"), HBox("test")
  end
end
