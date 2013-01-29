$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/helper"

class HelperTest < YCP::TestCase

  def test_ruby_regexp
    assert_equal "", YCP::Helper.ruby_regexp("")
    assert_equal "\\A", YCP::Helper.ruby_regexp("^")
    assert_equal "\\z", YCP::Helper.ruby_regexp("$")
    assert_equal "\\A\\z", YCP::Helper.ruby_regexp("^$")
    assert_equal "\\Aabcd\\z", YCP::Helper.ruby_regexp("^abcd$")
  end

end