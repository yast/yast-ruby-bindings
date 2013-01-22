$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/builtins"
require "ycp/path"

class BuiltinsPathTest < YCP::TestCase
  def test_add_list
    a = [1,2]
    assert_equal [1,2,3], YCP::Builtins.add(a,3)
    assert_equal [1,2], a
  end

  def test_add_map
    h = { :a => 1, :b => 2 }
    res = YCP::Builtins.add(h,:c,3)
    assert_equal ({:a => 1, :b => 2, :c => 3}),res
    assert_equal ({:a => 1, :b => 2}), h
  end

  def test_add_path
    p1 = YCP::Path.new(".etc")
    p2 = YCP::Path.new(".sysconfig")
    p3 = "sysconfig"
    expected_res = YCP::Path.new(".etc.sysconfig")
    assert_equal expected_res, YCP::Builtins.add(p1,p2)
    assert_equal expected_res, YCP::Builtins.add(p1,p3)
    assert_equal YCP::Path.new(".etc"),p1
  end

  def test_substring
    str = "12345"

    assert_equal str, YCP::Builtins.substring(str, 0)
    assert_equal "345", YCP::Builtins.substring(str, 2)

    assert_equal "", YCP::Builtins.substring(str, 2, 0)
    assert_equal "34", YCP::Builtins.substring(str, 2, 2)

    # tests from YCP documentation
    assert_equal "text", YCP::Builtins.substring("some text", 5)
    assert_equal "", YCP::Builtins.substring("some text", 42)
    assert_equal "te", YCP::Builtins.substring("some text", 5, 2)
    assert_equal "", YCP::Builtins.substring("some text", 42, 2)
    assert_equal "345", YCP::Builtins.substring("123456789", 2, 3)

    # check some corner cases to be YCP compatible
    assert_equal nil, YCP::Builtins.substring(nil, 2)
    assert_equal "", YCP::Builtins.substring(str, -1)
    assert_equal "345", YCP::Builtins.substring(str, 2, -1)

    assert_equal nil, YCP::Builtins.substring(str, nil)
    assert_equal nil, YCP::Builtins.substring(str, nil, nil)
    assert_equal nil, YCP::Builtins.substring(str, 1, nil)
  end
end
