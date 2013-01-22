$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/builtins"
require "ycp/path"

class BuiltinsPathTest < YCP::TestCase
  def test_add_array
    a = [1,2]
    assert_equal [1,2,3], YCP::Builtins.add(a,3)
    assert_equal [1,2], a
  end

  def test_add_hash
    h = { :a => 1, :b => 2 }
    res = YCP::Builtins.add(h,:c,3)
    assert_equal ({:a => 1, :b => 2, :c => 3}),res
    assert_equal ({:a => 1, :b => 2}), h
  end

  def test_add_path
    p1 = YCP::Path.new (".etc")
    p2 = YCP::Path.new (".sysconfig")
    p3 = "sysconfig"
    expected_res = YCP::Path.new(".etc.sysconfig")
    assert_equal expected_res, YCP::Builtins.add(p1,p2)
    assert_equal expected_res, YCP::Builtins.add(p1,p3)
    assert_equal YCP::Path.new(".etc"),p1
  end
end
