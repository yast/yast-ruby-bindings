# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/builtins"
require "ycp/path"
require "ycp/term"

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

  def test_issubstring
    assert_equal nil, YCP::Builtins.issubstring(nil, nil)
    assert_equal nil, YCP::Builtins.issubstring("", nil)
    assert_equal nil, YCP::Builtins.issubstring(nil, "")

    assert_equal true, YCP::Builtins.issubstring("abcd", "bc")
    assert_equal false, YCP::Builtins.issubstring("ABC", "abc")
    assert_equal true, YCP::Builtins.issubstring("a", "a")
    assert_equal true, YCP::Builtins.issubstring("", "")
  end

  def test_splitstring
    assert_equal nil, YCP::Builtins.splitstring(nil, nil)
    assert_equal nil, YCP::Builtins.splitstring("", nil)
    assert_equal nil, YCP::Builtins.splitstring(nil, "")
    assert_equal [], YCP::Builtins.splitstring("", "")
    assert_equal [], YCP::Builtins.splitstring("ABC", "")

    assert_equal ["a", "b", "c", "d"], YCP::Builtins.splitstring("a b c d", " ")
    assert_equal ["ABC"], YCP::Builtins.splitstring("ABC", "abc")

    assert_equal ["a", "", "", "a"], YCP::Builtins.splitstring("a   a", " ")
    assert_equal ["text", "with", "different", "separators"], YCP::Builtins.splitstring("text/with:different/separators", "/:")
  end

  def test_regexpmatch
    assert_equal nil, YCP::Builtins.regexpmatch(nil, nil)
    assert_equal nil, YCP::Builtins.regexpmatch("", nil)
    assert_equal true, YCP::Builtins.regexpmatch("", "")
    assert_equal true, YCP::Builtins.regexpmatch("abc", "")

    assert_equal true, YCP::Builtins.regexpmatch("abc", "^a")
    assert_equal true, YCP::Builtins.regexpmatch("abc", "c$")
  end

  def test_tolower
    assert_equal nil, YCP::Builtins.tolower(nil)
    assert_equal "", YCP::Builtins.tolower("")
    assert_equal "abc", YCP::Builtins.tolower("abc")
    assert_equal "abc", YCP::Builtins.tolower("ABC")
    assert_equal "abcÁÄÖČ", YCP::Builtins.tolower("ABCÁÄÖČ")
  end

  def test_toupper
    assert_equal nil, YCP::Builtins.toupper(nil)
    assert_equal "", YCP::Builtins.toupper("")
    assert_equal "ABC", YCP::Builtins.toupper("ABC")
    assert_equal "ABC", YCP::Builtins.toupper("abc")
    assert_equal "ABCáäöč", YCP::Builtins.toupper("abcáäöč")
  end

  def test_size
    assert_equal nil, YCP::Builtins.size(nil)
    assert_equal 0, YCP::Builtins.size([])
    assert_equal 0, YCP::Builtins.size({})
    assert_equal 0, YCP::Builtins.size("")

    assert_equal 0, YCP::Builtins.size(YCP::Term.new(:HBox))
    assert_equal 1, YCP::Builtins.size(YCP::Term.new(:HBox, "test"))
    assert_equal 2, YCP::Builtins.size(YCP::Term.new(:HBox, "test", "test"))
    assert_equal 1, YCP::Builtins.size(YCP::Term.new(:HBox, YCP::Term.new(:VBox, "test", "test")))
  end

  def test_time
    assert YCP::Builtins.time > 0
  end
end
