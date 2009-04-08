#
# Test loading of the bindings
#

$:.unshift "../../build/src/ruby"

# test loading of extension
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'ycp'
    assert true
  end
end
