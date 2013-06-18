# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/builtins"
require "ycp/path"
require "ycp/term"
require "ycp/break"

class BuiltinsTest < YCP::TestCase

  ADD_TEST_DATA = [
    [ nil, 5, nil],
    [ [1,2], 3, [1,2,3]],
    [ { :a => 1, :b => 2 },[:c,3],{ :a => 1, :b => 2, :c => 3}],
    [ YCP::Path.new(".etc"),
      YCP::Path.new(".sysconfig"),
      YCP::Path.new(".etc.sysconfig") ],
    [ YCP::Path.new(".etc"), "sysconfig", YCP::Path.new(".etc.sysconfig")],
    [ YCP::Term.new(:a, :b), :c, YCP::Term.new(:a, :b, :c)],
  ]
  def test_add
    ADD_TEST_DATA.each do |object, element, result|
      duplicate_object = object.nil? ? nil : object.dup
      res = YCP::Builtins.add(duplicate_object, *element)
      assert_equal result, res
      assert_equal object, duplicate_object
    end
  end

  def test_add_deep_copy
    a = [["a"]]
    b = YCP::Builtins.add(a, "b")
    b[0][0] = "c"
    assert_equal [["a"]], a
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
    assert_equal true, YCP::Builtins.regexpmatch("abc", "^[^][%]bc$")
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

    #from sysconfig remove whitespaces
    assert_equal "lest test\tsrst", YCP::Builtins.regexpsub(" lest test\tsrst\t", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")
    assert_equal "", YCP::Builtins.regexpsub("", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")
    assert_equal "", YCP::Builtins.regexpsub("  \t  ", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")

    # the result must be UTF-8 string
    assert_equal Encoding::UTF_8, YCP::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e").encoding
  end

  def test_regexptokenize
    assert_equal ["aaabbB"], YCP::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*")
    assert_equal ["aaab", "bb"], YCP::Builtins.regexptokenize("aaabbb", "(.*ab)(.*)")
    assert_equal [], YCP::Builtins.regexptokenize("aaabbb", "(.*ba).*")
    assert_equal nil, YCP::Builtins.regexptokenize("aaabbb", "(.*ba).*(");

    # the result must be UTF-8 string
    assert_equal Encoding::UTF_8, YCP::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*").first.encoding
  end

  def test_tohexstring
    assert_equal nil, YCP::Builtins.tohexstring(nil)
    assert_equal nil, YCP::Builtins.tohexstring(nil, nil)
    assert_equal "0x0", YCP::Builtins.tohexstring(0)
    assert_equal "0xa", YCP::Builtins.tohexstring(10)
    assert_equal "0xff", YCP::Builtins.tohexstring(255)
    assert_equal "0x3640e", YCP::Builtins.tohexstring(222222)

    assert_equal "0x1f", YCP::Builtins.tohexstring(31, 0)
    assert_equal "0x1f", YCP::Builtins.tohexstring(31, 1)
    assert_equal "0x001f", YCP::Builtins.tohexstring(31, 4)
    assert_equal "0x00001f", YCP::Builtins.tohexstring(31, 6)

    assert_equal "0x1f", YCP::Builtins.tohexstring(31, -1)
    assert_equal "0x1f ", YCP::Builtins.tohexstring(31, -3)

    assert_equal "0xfffffffffffffffd", YCP::Builtins.tohexstring(-3)
    assert_equal "0xfffffffffffffffd", YCP::Builtins.tohexstring(-3, 5)
    assert_equal "0x00fffffffffffffffd", YCP::Builtins.tohexstring(-3, 18)
    assert_equal "0x000000fffffffffffffffd", YCP::Builtins.tohexstring(-3, 22)

    assert_equal "0xfffffffffffffffd", YCP::Builtins.tohexstring(-3, -16)
    assert_equal "0xfffffffffffffffd ", YCP::Builtins.tohexstring(-3, -17)
    assert_equal "0xfffffffffffffffd      ", YCP::Builtins.tohexstring(-3, -22)
  end

  def test_timestring
    assert_equal nil, YCP::Builtins.timestring(nil, nil, nil)

    # disabled: system dependent (depends on the current system time zone),
    # fails if the current offset is not UTC+2:00
    # assert_equal "Mon May  6 13:29:56 2013", YCP::Builtins.timestring("%c", 1367839796, false)
    assert_equal "Mon May  6 11:29:56 2013", YCP::Builtins.timestring("%c", 1367839796, true)
    assert_equal "20130506", YCP::Builtins.timestring("%Y%m%d", 1367839796, false)
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

  def test_toascii
    assert_equal nil, YCP::Builtins.toascii(nil)
    assert_equal "", YCP::Builtins.toascii("")
    assert_equal "abc123XYZ", YCP::Builtins.toascii("abc123XYZ")
    assert_equal "abc123XYZ", YCP::Builtins.toascii("áabcě123čXYZŽž")
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

  def test_find_string
    assert_equal nil, YCP::Builtins.find(nil, nil)
    assert_equal nil, YCP::Builtins.find("", nil)

    assert_equal 0, YCP::Builtins.find("", "")
    assert_equal 2, YCP::Builtins.find("1234", "3")
    assert_equal 2, YCP::Builtins.find("1234", "3")
    assert_equal -1, YCP::Builtins.find("1234", "9")
  end

  def test_find_list
    test_list = [2,3,4]
    assert_equal nil, YCP::Builtins.find(nil) {|i| next true }
    assert_equal 2, YCP::Builtins.find(test_list) {|i| next true }
    assert_equal 3, YCP::Builtins.find(test_list) {|i| next i>2 }
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

    assert_equal [1, 2, 5, 10, 20, 200, "10", "15"], YCP::Builtins.sort(["10", 1, 2, 10, 20, "15", 200, 5])

    assert_equal [20,10,1], YCP::Builtins.sort([10,1,20]){ |x,y| x>y }
  end

  def test_toset
    assert_equal nil, YCP::Builtins.toset(nil)

    assert_equal [], YCP::Builtins.toset([])
    assert_equal ["A"], YCP::Builtins.toset(["A"])
    assert_equal ["A", "Z"], YCP::Builtins.toset(["Z", "A"])
    assert_equal [1, 2, 3], YCP::Builtins.toset([3, 2, 2, 1, 2, 1, 3, 1, 3, 3])

    assert_equal [false, true, 1, 2, 3, 5], YCP::Builtins.toset([1, 5, 3, 2, 3, true, false, true])
  end


  TOSTRING_TEST_DATA = [
    [ nil, "nil"],
    [ true, "true"],
    [ false, "false"],
    [ "test", "test" ],
    [ :test, "`test"],
    [ 1, "1" ],
    [ 1.453, "1.453" ],
    [ ["test",:lest], '["test", `lest]'],
    [ YCP::Path.new(".etc.syconfig.\"-arg\""), ".etc.syconfig.\"-arg\""],
    [ YCP::Term.new(:id,["test",:lest]), "`id ([\"test\", `lest])"],
    [ { :test => "data" }, "$[`test:\"data\"]"]
  ]

  def test_tostring
    TOSTRING_TEST_DATA.each do |input,result|
      assert_equal result, YCP::Builtins.tostring(input)
    end
  end

  def test_tostring_with_precision
    assert_equal "1.5", YCP::Builtins.tostring(1.453, 1)
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
    assert YCP::Builtins.srandom() > 0
    assert_equal nil, YCP::Builtins.srandom(10)
  end

  def test_tointeger()
    assert_equal nil, YCP::Builtins.tointeger(nil)
    assert_equal nil, YCP::Builtins.tointeger("")
    assert_equal nil, YCP::Builtins.tointeger("foo")
    assert_equal 120, YCP::Builtins.tointeger(120)
    assert_equal 120, YCP::Builtins.tointeger("120")
    assert_equal 120, YCP::Builtins.tointeger("  120asdf")
    assert_equal 120, YCP::Builtins.tointeger(120.0)
    assert_equal 32, YCP::Builtins.tointeger("0x20")
    assert_equal 0, YCP::Builtins.tointeger(" 0x20")
    assert_equal 32, YCP::Builtins.tointeger("0x20Z")
    assert_equal 8, YCP::Builtins.tointeger("010")
    assert_equal -10, YCP::Builtins.tointeger("-10")

    # weird YCP cases
    assert_equal 0, YCP::Builtins.tointeger("-0x20")
    assert_equal 0, YCP::Builtins.tointeger(" 0x20")
    assert_equal 20, YCP::Builtins.tointeger(" 020")
    assert_equal -20, YCP::Builtins.tointeger("-020")
    assert_equal -20, YCP::Builtins.tointeger("-0020")
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

  def test_filter_list
    assert_equal nil, YCP::Builtins.filter(nil)
    assert_equal [2,3,4], YCP::Builtins.filter([2,3,4]) {|i| next true }
    assert_equal [4], YCP::Builtins.filter([2,3,4]){ |i| next i>3 }
    assert_equal [], YCP::Builtins.filter([2,3,4]){ |i| next i>4 }
  end

  def test_filter_map
    test_hash = {2=>3,3=>4}
    assert_equal Hash[2=>3,3=>4], YCP::Builtins.filter(test_hash) {|i,j| next true }
    assert_equal Hash[3=>4], YCP::Builtins.filter(test_hash){ |i,j| next i>2 }
    assert_equal Hash.new, YCP::Builtins.filter(test_hash){ |i,j| next i>4 }
  end

  def test_each_list
    assert_equal nil, YCP::Builtins.foreach(nil){|i| next 5}
    list = [2,3,4]
    cycle_detect = 0
    res = YCP::Builtins.foreach(list) do |l|
      cycle_detect += 1
      next l
    end
    assert_equal 4, res
    assert_equal 3, cycle_detect
    cycle_detect = 0
    res = YCP::Builtins.foreach(list) do |l|
      cycle_detect += 1
      raise YCP::Break if l == 3
    end
    assert_equal nil, res
    assert_equal 2, cycle_detect
    cycle_detect = 0
    res = YCP::Builtins.foreach(list) do |l|
      cycle_detect += 1
      next l+3
    end
    assert_equal 7, res
    assert_equal 3, cycle_detect
  end

  def test_each_map
    map = {2=>3,3=>4}
    cycle_detect = 0
    res = YCP::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      next k
    end
    assert_equal 3, res
    assert_equal 2, cycle_detect
    cycle_detect = 0
    res = YCP::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      raise YCP::Break if k == 2
    end
    assert_equal nil, res
    assert_equal 1, cycle_detect
    cycle_detect = 0
    res = YCP::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      next v+3
    end
    assert_equal 7, res
    assert_equal 2, cycle_detect
  end

  def test_maplist_list
    assert_equal nil, YCP::Builtins.maplist(nil){|i| next 5}

    list = [2,3,4]
    res = YCP::Builtins.maplist(list) do |l|
      next l
    end
    assert_equal [2,3,4], res

    res = YCP::Builtins.maplist(list) do |l|
      raise YCP::Break if l == 3
      l
    end
    assert_equal [2], res

    res = YCP::Builtins.maplist(list) do |l|
      next if l == 3
      next l+3
    end
    assert_equal [5,nil,7], res
  end

  def test_remove_list
    list = [0,1,2,3]

    assert_equal nil, YCP::Builtins.remove(nil,2)

    assert_equal [0,1,3], YCP::Builtins.remove(list,2)

    assert_equal [0,1,2,3], YCP::Builtins.remove(list,5)
    assert_equal [0,1,2,3], YCP::Builtins.remove(list,-1)
  end

  def test_remove_map
    list = {0 => 1, 2 => 3}

    assert_equal nil, YCP::Builtins.remove(nil,2)

    assert_equal Hash[0 => 1], YCP::Builtins.remove(list,2)
    assert_equal Hash[ 0 => 1, 2 => 3], list

    assert_equal Hash[ 0 => 1, 2 => 3], YCP::Builtins.remove(list,5)
  end

  def test_remove_term
    term = YCP::Term.new :t, :a, :b

    assert_equal YCP::Term.new(:t,:a), YCP::Builtins.remove(term,2)
    assert_equal YCP::Term.new(:t,:a,:b), term

    assert_equal YCP::Term.new(:t,:a,:b), YCP::Builtins.remove(term,5)
    assert_equal YCP::Term.new(:t,:a,:b), YCP::Builtins.remove(term,-1)
  end

  def test_select
    list = [0,1,2]
    assert_equal 1,YCP::Builtins.select(list,1,-1)
  end

  UNION_TESTDATA = [
    [nil,nil,nil],
    [nil,[3,4],nil],
    [[1,2],nil,nil],
    [[1,2],[3,4],[1,2,3,4]],
    [[1,2,3,1],[3,4],[1,2,3,4]],
    [[1,2,nil],[3,nil,4],[1,2,nil,3,4]],
    [{1=>2,2=>3},{2=>10,4=>5},{1=>2,2=>10,4=>5}],
  ]
  def test_union_list
    UNION_TESTDATA.each do |first,second,result|
      assert_equal result, YCP::Builtins.union(first, second)
    end
  end

  def test_float_abs
    assert_equal nil, YCP::Builtins::Float.abs(nil)

    assert_equal 5.4, YCP::Builtins::Float.abs(-5.4)
  end

  def test_float_ceil
    assert_equal nil, YCP::Builtins::Float.ceil(nil)

    assert_equal -5.0, YCP::Builtins::Float.ceil(-5.4)

    assert_equal 6.0, YCP::Builtins::Float.ceil(5.4)
    assert_equal Float, YCP::Builtins::Float.ceil(5.4).class
  end

  def test_float_floor
    assert_equal nil, YCP::Builtins::Float.floor(nil)

    assert_equal -6.0, YCP::Builtins::Float.floor(-5.4)

    assert_equal 5.0, YCP::Builtins::Float.floor(5.4)
    assert_equal Float, YCP::Builtins::Float.floor(5.4).class
  end

  def test_float_pow
    assert_equal nil, YCP::Builtins::Float.pow(nil,10.0)

    assert_equal 1000.0, YCP::Builtins::Float.pow(10.0,3.0)
    assert_equal Float, YCP::Builtins::Float.pow(10.0,3.0).class
  end

  def test_float_trunc
    assert_equal nil, YCP::Builtins::Float.trunc(nil)

    assert_equal -5.0, YCP::Builtins::Float.trunc(-5.4)

    assert_equal 5.0, YCP::Builtins::Float.trunc(5.6)
    assert_equal Float, YCP::Builtins::Float.trunc(5.4).class
  end

  TOFLOAT_TESTDATA = [
   [ 1, 1.0 ],
   [ nil, nil],
   [ "42", 42.0],
   [ "89.3", 89.3 ],
   [ "test", 0.0 ],
   [ :test, nil ]
  ]
  def test_tofloat
    TOFLOAT_TESTDATA.each do |value,result|
      assert_equal result, YCP::Builtins.tofloat(value)
    end
  end

  FLATTEN_TESTDATA = [
    [nil, nil],
    [[nil],nil],
    [[[1,2],nil],nil],
    [[[1,2],[3,nil]],[1,2,3,nil]],
    [[[0,1],[2,[3,4]]],[0,1,2,[3,4]]],
    [[[0,1],[2,3],[3,4]],[0,1,2,3,3,4]],
  ]
  def test_flatten
    FLATTEN_TESTDATA.each do |value,result|
      assert_equal result, YCP::Builtins.flatten(value)
    end
  end

  def test_list_reduce_1param
    list = [0,1,2,3,2,1,-5]
    res = YCP::Builtins::List.reduce(list) do |x,y|
      next x>y ? x : y
    end

    assert_equal 3, res

    res = YCP::Builtins::List.reduce(list) do |x,y|
      next x + y
    end
    assert_equal 4, res

    assert_equal nil, YCP::Builtins::List.reduce([]) { |x,y| next x }
    assert_equal nil, YCP::Builtins::List.reduce(nil) { |x,y| next x }
  end

  def test_list_reduce_2params
    list = [0,1,2,3,2,1,-5]
    res = YCP::Builtins::List.reduce(15,list) do |x,y|
      next x>y ? x : y
    end

    assert_equal 15, res

    res = YCP::Builtins::List.reduce(15,list) do |x,y|
      next x + y
    end

    assert_equal 19, res

    assert_equal 5, YCP::Builtins::List.reduce(5,[]) { |x,y| next x }
    assert_equal nil, YCP::Builtins::List.reduce(nil,nil) { |x,y| next x }
  end

  SWAP_TESTDATA = [
    [nil,nil,nil,nil],
    [[0],nil,0,nil],
    [[0],0,nil,nil],
    [[0],0,nil,nil],
    [[5,6],-1,1,[5,6]],
    [[5,6],0,2,[5,6]],
    [[0,1,2,3],0,3,[3,2,1,0]],
    [[0,1,2,3],0,2,[2,1,0,3]],
    [[0,1,2,3],1,3,[0,3,2,1]],
    [[0,1,2,3],2,2,[0,1,2,3]],
  ]
  def test_list_swap
    SWAP_TESTDATA.each do |list,offset1,offset2,result|
      list_prev = list.nil? ? nil : list.dup 
      assert_equal result, YCP::Builtins::List.swap(list, offset1, offset2)
      #check that list is not modified
      assert_equal list_prev, list
    end
  end

  def test_listmap
    assert_equal nil, YCP::Builtins.listmap(nil) {|i| next {i => i}}

    assert_equal Hash[1=>1,2=>2], YCP::Builtins.listmap([1,2]) {|i| next {i => i}}

  end

  PREPEND_TESTDATA = [
    [nil,5,nil],
    [[0,1],5,[5,0,1]],
    [[1,2],nil,[nil,1,2]],
  ]
  def test_prepend
    PREPEND_TESTDATA.each do |list,element,result|
      list_prev = list.nil? ? nil : list.dup 
      assert_equal result, YCP::Builtins.prepend(list, element)
      #check that list is not modified
      assert_equal list_prev, list
    end 
  end

  SUBLIST_TEST_DATA_WITH_LEN = [
    [nil,1,1,nil],
    [[0,1],nil,nil,nil],
    [[0,1],2,1,nil],
    [[0,1],1,2,nil],
    [[0,1],1,1,[1]],
    [[0,1],1,0,[]],
  ]
  def test_sublist_with_len
    SUBLIST_TEST_DATA_WITH_LEN.each do |list,offset,length,result|
      list_prev = list.nil? ? nil : list.dup 
      assert_equal result, YCP::Builtins.sublist(list, offset, length)
      #check that list is not modified
      assert_equal list_prev, list
    end 
  end

  SUBLIST_TEST_DATA_WITHOUT_LEN = [
    [nil,1,nil],
    [[0,1],nil,nil],
    [[0,1],2,nil],
    [[0,1],0,[0,1]],
    [[0,1],1,[1]],
  ]
  def test_sublist_without_len
    SUBLIST_TEST_DATA_WITHOUT_LEN.each do |list,offset,result|
      list_prev = list.nil? ? nil : list.dup 
      assert_equal result, YCP::Builtins.sublist(list, offset)
      #check that list is not modified
      assert_equal list_prev, list
    end 
  end

  def test_mapmap
    assert_equal nil, YCP::Builtins.listmap(nil) {|k,v| next {v => k}}

    assert_equal Hash[1=>2,3=>4], YCP::Builtins.mapmap({2=>1,4=>3}) {|k,v| next {v => k}}

    res = YCP::Builtins.mapmap({2=>1,4=>3}) do |k,v|
      raise YCP::Break if k == 4
      next {v => k}
    end

    assert_equal Hash[1=>2],res
  end

  def test_random
    assert_equal nil,YCP::Builtins.random(nil)

    # there is quite nice chance with this repetition to test even border or range
    100.times do
      assert (0..9).include? YCP::Builtins.random(10)
    end
  end

  def test_topath
    assert_equal nil, YCP::Builtins.topath(nil)

    assert_equal YCP::Path.new(".etc"), YCP::Builtins.topath(YCP::Path.new(".etc"))

    assert_equal YCP::Path.new(".etc"), YCP::Builtins.topath(".etc")

    assert_equal YCP::Path.new(".etc"), YCP::Builtins.topath("etc")
  end
  def test_sformat
    assert_equal nil, YCP::Builtins.sformat(nil)
    assert_equal "test", YCP::Builtins.sformat("test")
    assert_equal "test %1", YCP::Builtins.sformat("test %1")
    assert_equal "test", YCP::Builtins.sformat("test%a","lest")
    assert_equal "test%", YCP::Builtins.sformat("test%%","lest")
    assert_equal "test321", YCP::Builtins.sformat("test%3%2%1",1,2,3)

    assert_equal "test lest", YCP::Builtins.sformat("test %1","lest")

    assert_equal "test `lest", YCP::Builtins.sformat("test %1",:lest)
  end


  FINDFIRSTOF_TESTDATA = [
    [nil,"ab",nil],
    ["ab",nil,nil],
    ["aaaaa","z",nil],
    ["abcdefg","cxdv",2],
    ["\s\t\n","\s",0],
    ["\s\t\n","\n",2]
  ]
  def test_findfirstof
    FINDFIRSTOF_TESTDATA.each do |string,chars,result|
      assert_equal result, YCP::Builtins.findfirstof(string,chars)
    end
  end

  FINDFIRSTNOTOF_TESTDATA = [
    [nil,"ab",nil],
    ["ab",nil,nil],
    ["aaaaa","z",0],
    ["abcdefg","cxdv",0],
    ["\s\t\n","\s",1],
    ["\n\n\t","\n",2]
  ]
  def test_findfirstnotof
    FINDFIRSTNOTOF_TESTDATA.each do |string,chars,result|
      assert_equal result, YCP::Builtins.findfirstnotof(string,chars)
    end
  end

  FINDLASTOF_TESTDATA = [
    [nil,"ab",nil],
    ["ab",nil,nil],
    ["aaaaa","z",nil],
    ["abcdefg","cxdv",3],
    ["\s\t\n","\s",0],
    ["\s\t\n","\n",2]
  ]
  def test_findlastof
    FINDLASTOF_TESTDATA.each do |string,chars,result|
      assert_equal result, YCP::Builtins.findlastof(string,chars)
    end
  end

  FINDLASTNOTOF_TESTDATA = [
    [nil,"ab",nil],
    ["ab",nil,nil],
    ["aaaaa","z",4],
    ["abcdefg","cxdv",6],
    ["\s\t\s","\s",1],
    ["\t\n\n","\n",0]
  ]
  def test_findlastnotof
    FINDLASTNOTOF_TESTDATA.each do |string,chars,result|
      assert_equal result, YCP::Builtins.findlastnotof(string,chars)
    end
  end

  def test_float_tolstring
    old_lang = ENV["LANG"]
    ENV["LANG"] = "cs_CZ.utf-8"
    ret = YCP::Builtins::Float.tolstring(0.52,1)
    assert_equal "0,5", ret
    assert_equal Encoding::UTF_8, ret.encoding
    ENV["LANG"] = old_lang
  end

  def test_crypt
    # crypt is salted so cannot reproduce, just test if run and returns something useful
    ["", "md5", "blowfish", "sha256", "sha512"].each do |suffix|
      res = YCP::Builtins.send(:"crypt#{suffix}", "test")
      assert res;
      assert (res.size>10), "res too small #{res} for crypt#{suffix}"
    end
  end

  def test_lsort
    assert_equal ["a", "b", "c"], YCP::Builtins.lsort(["c", "b", "a"])
    assert_equal [1, 2, 3], YCP::Builtins.lsort([3, 2, 1])
    assert_equal [1, 2, 3, "a", "b"], YCP::Builtins.lsort([3, "a", 2, "b", 1])
    assert_equal [true, 50, "a", "z"], YCP::Builtins.lsort(["a", 50, "z", true])
  end

  EVAL_TEST_DATA = [
    [nil, nil],
    [5, 5],
    [ Proc.new() { "15" }, "15"],
  ]

  def test_eval
    EVAL_TEST_DATA.each do |input, result|
      assert_equal result, YCP::Builtins.eval(input)
    end
  end

  DELETECHARS_TEST_DATA = [
    [ nil, nil, nil ],
    [ "test", nil, nil ],
    [ nil, "a", nil ],
    [ "a", "abcdefgh", ""],
    [ "abc", "cde", "ab"],
    [ "abc", "a-c", "b"],
    [ "abc", "^ab", "c"]
  ]

  def test_deletechars
    DELETECHARS_TEST_DATA.each do |input1, input2, result|
      assert_equal result, YCP::Builtins.deletechars(input1, input2)
    end
  end

  FILTERCHARS_TEST_DATA = [
    [ nil, nil, nil ],
    [ "test", nil, nil ],
    [ nil, "a", nil ],
    [ "a", "abcdefgh", "a"],
    [ "abc", "cde", "c"],
    [ "abc", "a-c", "ac"],
    [ "abc", "^ab", "ab"]
  ]

  def test_filterchars
    FILTERCHARS_TEST_DATA.each do |input1, input2, result|
      assert_equal result, YCP::Builtins.filterchars(input1, input2)
    end
  end

  TOTERM_TEST_DATA = [
    [ "test", YCP::Term.new(:test) ],
    [ :test, YCP::Term.new(:test) ],
    [ [:test, [:lest, :srst]], YCP::Term.new(:test, :lest, :srst) ],
    [ YCP::Term.new(:test), YCP::Term.new(:test) ],
  ]

  def test_toterm
    TOTERM_TEST_DATA.each do |input, res|
      assert_equal res, YCP::Builtins.toterm(*input)
    end
  end

  def test_multiset_union
    assert_equal [1,2,3], YCP::Builtins::Multiset.union([1,2],[2,3])
  end

  def test_multiset_includes
    assert_equal false, YCP::Builtins::Multiset.includes([1,2],[2,3])
    assert_equal false, YCP::Builtins::Multiset.includes([1,2],[2,2])
    assert_equal true, YCP::Builtins::Multiset.includes([1,2],[2])
  end

  def test_multiset_difference
    assert_equal [1], YCP::Builtins::Multiset.difference([1,2],[2,3])
  end

  def test_multiset_symmetric_difference
    assert_equal [1,3], YCP::Builtins::Multiset.symmetric_difference([1,2],[2,3])
    assert_equal [1,2], YCP::Builtins::Multiset.symmetric_difference([1,2],[2,2])
    assert_equal [1,1,2,2], YCP::Builtins::Multiset.symmetric_difference([1,1,2],[2,2,2])
  end

  def test_multiset_intersection
    assert_equal [2], YCP::Builtins::Multiset.intersection([1,2],[2,3])
    assert_equal [2,2], YCP::Builtins::Multiset.intersection([1,2,2],[2,2,3])
  end

  def test_multiset_union
    assert_equal [1,2,3], YCP::Builtins::Multiset.union([1,2],[2,3])
    assert_equal [1,2,2,3], YCP::Builtins::Multiset.union([1,2,2],[2,2,3])
  end

  def test_multiset_merge
    assert_equal [1,2,2,3], YCP::Builtins::Multiset.merge([1,2],[2,3])
    assert_equal [1,2,2,2,2,3], YCP::Builtins::Multiset.merge([1,2,2],[2,2,3])
    assert_equal [2,1,2,2,3,2], YCP::Builtins::Multiset.merge([2,1,2],[2,3,2])
  end

  def test_deep_copy
    a = [[1,2],[2,3]]
    b = YCP.deep_copy a
    b[0][0] = 10
    assert_equal 1, a[0][0]
    assert_equal 10, b[0][0]
  end
end
