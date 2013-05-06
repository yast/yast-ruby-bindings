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

  def test_mergestring
    assert_equal nil, YCP::Builtins.mergestring(nil, nil)
    assert_equal nil, YCP::Builtins.mergestring([], nil)
    assert_equal nil, YCP::Builtins.mergestring(nil, "")

    assert_equal "", YCP::Builtins.mergestring([], "")
    assert_equal "ABC", YCP::Builtins.mergestring(["A", "B", "C"], "")
    assert_equal "A B C", YCP::Builtins.mergestring(["A", "B", "C"], " ")

    assert_equal "a b c d", YCP::Builtins.mergestring(["a", "b", "c", "d"], " ")
    assert_equal "ABC", YCP::Builtins.mergestring(["ABC"], "abc")
    assert_equal "a   a", YCP::Builtins.mergestring(["a", "", "", "a"], " ")

    # tests from Yast documentation
    assert_equal "/abc/dev/ghi", YCP::Builtins.mergestring(["", "abc", "dev", "ghi"], "/")
    assert_equal "abc/dev/ghi/", YCP::Builtins.mergestring(["abc", "dev", "ghi", ""], "/")
    assert_equal "1.a.3", YCP::Builtins.mergestring([1, "a", 3], ".")
    assert_equal "1.a.3", YCP::Builtins.mergestring(["1", "a", "3"], ".")
    assert_equal "", YCP::Builtins.mergestring([], ".")
    assert_equal "abcdevghi", YCP::Builtins.mergestring(["abc", "dev", "ghi"], "")
    assert_equal "abc123dev123ghi", YCP::Builtins.mergestring(["abc", "dev", "ghi"], "123")
  end

  def test_regexpmatch
    assert_equal nil, YCP::Builtins.regexpmatch(nil, nil)
    assert_equal nil, YCP::Builtins.regexpmatch("", nil)
    assert_equal true, YCP::Builtins.regexpmatch("", "")
    assert_equal true, YCP::Builtins.regexpmatch("abc", "")

    assert_equal true, YCP::Builtins.regexpmatch("abc", "^a")
    assert_equal true, YCP::Builtins.regexpmatch("abc", "c$")
  end

  def test_regexppos
    assert_equal nil, YCP::Builtins.regexppos(nil, nil)
    assert_equal [0, 0], YCP::Builtins.regexppos("", "")

    # from YCP documentation
    assert_equal [4, 3], YCP::Builtins.regexppos("abcd012efgh345", "[0-9]+")
    assert_equal [], YCP::Builtins.regexppos("aaabbb", "[0-9]+")
  end

  def test_regexpsub
    assert_equal nil, YCP::Builtins.regexpsub(nil, nil, nil)

    # from YCP documentation
    assert_equal "s_aaab_e", YCP::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e")
    assert_equal nil, YCP::Builtins.regexpsub("aaabbb", "(.*ba)", "s_\\1_e")
  end

  def test_regexptokenize
    assert_equal ["aaabbB"], YCP::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*")
    assert_equal ["aaab", "bb"], YCP::Builtins.regexptokenize("aaabbb", "(.*ab)(.*)")
    assert_equal [], YCP::Builtins.regexptokenize("aaabbb", "(.*ba).*")
    assert_equal nil, YCP::Builtins.regexptokenize("aaabbb", "(.*ba).*(");
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

  def test_find
    assert_equal nil, YCP::Builtins.find(nil, nil)
    assert_equal nil, YCP::Builtins.find("", nil)

    assert_equal 0, YCP::Builtins.find("", "")
    assert_equal 2, YCP::Builtins.find("1234", "3")
    assert_equal 2, YCP::Builtins.find("1234", "3")
    assert_equal -1, YCP::Builtins.find("1234", "9")
  end

  def test_contains
    assert_equal nil, YCP::Builtins.contains(nil, nil)
    assert_equal nil, YCP::Builtins.contains([], nil)
    assert_equal nil, YCP::Builtins.contains(nil, "")

    assert_equal false, YCP::Builtins.contains([], "")
    assert_equal false, YCP::Builtins.contains(["A", "B", "C"], "")
    assert_equal false, YCP::Builtins.contains(["A", "B", "C"], "X")
    assert_equal true, YCP::Builtins.contains(["A", "B", "C"], "B")
  end

  def test_merge
    assert_equal nil, YCP::Builtins.merge(nil, nil)
    assert_equal nil, YCP::Builtins.merge([], nil)
    assert_equal nil, YCP::Builtins.merge(nil, [])

    assert_equal [], YCP::Builtins.merge([], [])
    assert_equal ["A"], YCP::Builtins.merge(["A"], [])
    assert_equal ["A", "B"], YCP::Builtins.merge(["A"], ["B"])
    assert_equal ["A", 1], YCP::Builtins.merge(["A"], [1])
  end

  def test_sort
    assert_equal nil, YCP::Builtins.sort(nil)

    assert_equal [], YCP::Builtins.sort([])
    assert_equal ["A"], YCP::Builtins.sort(["A"])
    assert_equal ["A", "Z"], YCP::Builtins.sort(["Z", "A"])
    assert_equal [1, 2, 3], YCP::Builtins.sort([3, 2, 1])

    # TODO FIXME: fails, do we need to fix it???
    # assert_equal [1, 2, 5, 10, 20, 200, "10", "15"], YCP::Builtins.sort(["10", 1, 2, 10, 20, "15", 200, 5])
  end

  def test_toset
    assert_equal nil, YCP::Builtins.toset(nil)

    assert_equal [], YCP::Builtins.toset([])
    assert_equal ["A"], YCP::Builtins.toset(["A"])
    assert_equal ["A", "Z"], YCP::Builtins.toset(["Z", "A"])
    assert_equal [1, 2, 3], YCP::Builtins.toset([3, 2, 2, 1, 2, 1, 3, 1, 3, 3])

    # TODO FIXME: fails, do we need to fix it???
    # assert_equal [false, true, 1, 2, 3, 5], YCP::Builtins.toset([1, 5, 3, 2, 3, true, false, true])
  end

  def test_tostring
    assert_equal "<NULL>", YCP::Builtins.tostring(nil)
    assert_equal "", YCP::Builtins.tostring("")
    assert_equal "str", YCP::Builtins.tostring("str")
    assert_equal "[]", YCP::Builtins.tostring([])
    assert_equal "[1, 2]", YCP::Builtins.tostring([1, 2])
    assert_equal "3.1415", YCP::Builtins.tostring(3.1415)
    assert_equal "42", YCP::Builtins.tostring(42)
    assert_equal "`sym", YCP::Builtins.tostring(:sym)
    assert_equal "`term ()", YCP::Builtins.tostring(YCP::Term.new(:term))
    assert_equal "`term (`term (`t))", YCP::Builtins.tostring(YCP::Term.new(:term, YCP::Term.new(:term, :t)))

    # TODO FIXME: Hash does not work, do we need to fix it?
    # assert_equal "$[]", YCP::Builtins.tostring({})
  end

  def test_change
    a = [1,2]
    assert_equal [1,2,3], YCP::Builtins.change(a,3)
    assert_equal [1,2], a

    h = { :a => 1, :b => 2 }
    res = YCP::Builtins.change(h, :c, 3)
    assert_equal ({:a => 1, :b => 2, :c => 3}),res
    assert_equal ({:a => 1, :b => 2}), h
  end

  def test_isempty
    assert_equal nil, YCP::Builtins.isempty(nil)
    assert_equal true, YCP::Builtins.isempty([])
    assert_equal true, YCP::Builtins.isempty({})
    assert_equal true, YCP::Builtins.isempty("")
    assert_equal false, YCP::Builtins.isempty([1])
    assert_equal false, YCP::Builtins.isempty({"a" => "b"})
    assert_equal false, YCP::Builtins.isempty("foo")
  end

  def test_srandom
    assert_equal nil, YCP::Builtins.srandom(nil)
    assert YCP::Builtins.srandom() > 0
    assert_equal nil, YCP::Builtins.srandom(10)
  end

  def test_tointeger()
    assert_equal nil, YCP::Builtins.tointeger(nil)
    assert_equal 120, YCP::Builtins.tointeger(120)
    assert_equal 120, YCP::Builtins.tointeger("120")
    assert_equal 120, YCP::Builtins.tointeger(120.0)
  end

  def test_search
    assert_equal nil, YCP::Builtins.search(nil, nil)
    assert_equal nil, YCP::Builtins.search("", nil)

    assert_equal 0, YCP::Builtins.search("", "")
    assert_equal 2, YCP::Builtins.search("1234", "3")
    assert_equal 2, YCP::Builtins.search("1234", "3")
    assert_equal nil, YCP::Builtins.search("1234", "9")
  end

  def test_haskey
    assert_equal nil, YCP::Builtins.haskey(nil, nil)
    assert_equal nil, YCP::Builtins.haskey({}, nil)
    assert_equal nil, YCP::Builtins.haskey(nil, "")

    assert_equal false, YCP::Builtins.haskey({}, "")
    assert_equal true, YCP::Builtins.haskey({"a" => 1}, "a")
    assert_equal false, YCP::Builtins.haskey({"a" => 1}, "b")
  end

  def test_lookup
    assert_equal nil, YCP::Builtins.lookup({}, nil, nil)
    assert_equal nil, YCP::Builtins.lookup({}, "", nil)
    assert_equal 1, YCP::Builtins.lookup({"a" => 1}, "a", 2)
    assert_equal 2, YCP::Builtins.lookup({"a" => 1}, "b", 2)
  end
end
