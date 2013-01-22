#
# Test loading of the bindings
#

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

class LoadTest < YCP::TestCase
  def test_loadingx
    require 'ycpx'
    assert true
  end
  def test_loading
    require 'ycp'
    assert true
  end
end
