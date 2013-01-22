$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/term"

class TermTest < YCP::TestCase
  def test_initialize
    assert_equal :HBox, YCP::Term.new(:HBox).value
    assert_equal [], YCP::Term.new(:HBox).params
    assert_equal ["test"], YCP::Term.new(:HBox, "test").params
    assert_equal "test", YCP::Term.new(:HBox, "test").params.first
    
    assert_equal :VBox, YCP::Term.new(:HBox, YCP::Term.new(:VBox)).params.first.value
  end
  
  def test_update
    t = YCP::Term.new(:HBox, 1, 2)
    t.params[0] = 0
    assert_equal t.params.first, 0
  end

  def test_equal
    assert_equal YCP::Term.new(:HBox), YCP::Term.new(:HBox)
    assert_not_equal YCP::Term.new(:HBox), YCP::Term.new(:VBox)
    assert_not_equal YCP::Term.new(:HBox), YCP::Term.new(:HBox, "test")
  end

  def test_size
    assert_equal 0, YCP::Term.new(:HBox).size
    assert_equal 1, YCP::Term.new(:HBox, "test").size
    assert_equal 1, YCP::Term.new(:HBox, "test").size
    assert_equal 1, YCP::Term.new(:HBox, YCP::Term.new(:VBox, "test", "test")).size
  end

end
