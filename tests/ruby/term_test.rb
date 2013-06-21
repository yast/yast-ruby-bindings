$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "yast/term"

class TermTest < Yast::TestCase
  def test_initialize
    assert_equal :HBox, Yast::Term.new(:HBox).value
    assert_equal [], Yast::Term.new(:HBox).params
    assert_equal ["test"], Yast::Term.new(:HBox, "test").params
    assert_equal "test", Yast::Term.new(:HBox, "test").params.first

    assert_equal :VBox, Yast::Term.new(:HBox, Yast::Term.new(:VBox)).params.first.value
  end

  def test_update
    t = Yast::Term.new(:HBox, 1, 2)
    t.params[0] = 0
    assert_equal t.params.first, 0
  end

  def test_equal
    assert_equal Yast::Term.new(:HBox), Yast::Term.new(:HBox)
    assert_not_equal Yast::Term.new(:HBox), Yast::Term.new(:VBox)
    assert_not_equal Yast::Term.new(:HBox), Yast::Term.new(:HBox, "test")
  end

  def test_size
    assert_equal 0, Yast::Term.new(:HBox).size
    assert_equal 1, Yast::Term.new(:HBox, "test").size
    assert_equal 1, Yast::Term.new(:HBox, "test").size
    assert_equal 1, Yast::Term.new(:HBox, Yast::Term.new(:VBox, "test", "test")).size
  end

end
