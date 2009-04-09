#
# Test loading of the bindings
#

$:.unshift "../../build/src/ruby" # ycpx.so
$:.unshift "../../src/ruby"       # ycp.rb

# test loading of extension
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loadingx
    require 'ycpx'
    assert true
  end
  def test_loading
    require 'ycp'
    assert true
  end
end
