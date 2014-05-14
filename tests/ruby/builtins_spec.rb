# encoding: utf-8

require_relative "test_helper_rspec"

require "yast/builtins"
require "yast/path"
require "yast/term"
require "yast/break"

describe "BuiltinsTest" do

  ADD_TEST_DATA = [
    [ nil, 5, nil],
    [ [1,2], 3, [1,2,3]],
    [ { :a => 1, :b => 2 },[:c,3],{ :a => 1, :b => 2, :c => 3}],
    [ Yast::Path.new(".etc"),
      Yast::Path.new(".sysconfig"),
      Yast::Path.new(".etc.sysconfig") ],
    [ Yast::Path.new(".etc"), "sysconfig", Yast::Path.new(".etc.sysconfig")],
    [ Yast::Term.new(:a, :b), :c, Yast::Term.new(:a, :b, :c)],
  ]
  it "tests add" do
    ADD_TEST_DATA.each do |object, element, result|
      duplicate_object = object.nil? ? nil : object.dup
      res = Yast::Builtins.add(duplicate_object, *element)
      expect(res).to eq(result)
      expect(duplicate_object).to eq(object)
    end
  end

  it "tests add deep copy" do
    a = [["a"]]
    b = Yast::Builtins.add(a, "b")
    b[0][0] = "c"
    expect(a).to eq([["a"]])
  end

  it "tests substring" do
    str = "12345"

    expect(Yast::Builtins.substring(str, 0)).to eq(str)
    expect(Yast::Builtins.substring(str, 2)).to eq("345")

    expect(Yast::Builtins.substring(str, 2, 0)).to eq("")
    expect(Yast::Builtins.substring(str, 2, 2)).to eq("34")

    # tests from Yast documentation
    expect(Yast::Builtins.substring("some text", 5)).to eq("text")
    expect(Yast::Builtins.substring("some text", 42)).to eq("")
    expect(Yast::Builtins.substring("some text", 5, 2)).to eq("te")
    expect(Yast::Builtins.substring("some text", 42, 2)).to eq("")
    expect(Yast::Builtins.substring("123456789", 2, 3)).to eq("345")

    # check some corner cases to be Yast compatible
    expect(Yast::Builtins.substring(nil, 2)).to eq(nil)
    expect(Yast::Builtins.substring(str, -1)).to eq("")
    expect(Yast::Builtins.substring(str, 2, -1)).to eq("345")

    expect(Yast::Builtins.substring(str, nil)).to eq(nil)
    expect(Yast::Builtins.substring(str, nil, nil)).to eq(nil)
    expect(Yast::Builtins.substring(str, 1, nil)).to eq(nil)
  end

  it "tests issubstring" do
    expect(Yast::Builtins.issubstring(nil, nil)).to eq(nil)
    expect(Yast::Builtins.issubstring("", nil)).to eq(nil)
    expect(Yast::Builtins.issubstring(nil, "")).to eq(nil)

    expect(Yast::Builtins.issubstring("abcd", "bc")).to eq(true)
    expect(Yast::Builtins.issubstring("ABC", "abc")).to eq(false)
    expect(Yast::Builtins.issubstring("a", "a")).to eq(true)
    expect(Yast::Builtins.issubstring("", "")).to eq(true)
  end

  it "tests splitstring" do
    expect(Yast::Builtins.splitstring(nil, nil)).to eq(nil)
    expect(Yast::Builtins.splitstring("", nil)).to eq(nil)
    expect(Yast::Builtins.splitstring(nil, "")).to eq(nil)
    expect(Yast::Builtins.splitstring("", "")).to eq([])
    expect(Yast::Builtins.splitstring("ABC", "")).to eq([])

    expect(Yast::Builtins.splitstring("a b c d", " ")).to eq(["a", "b", "c", "d"])
    expect(Yast::Builtins.splitstring("ABC", "abc")).to eq(["ABC"])

    expect(Yast::Builtins.splitstring("a   a", " ")).to eq(["a", "", "", "a"])
    expect(Yast::Builtins.splitstring("text/with:different/separators", "/:")).to eq(["text", "with", "different", "separators"])
  end

  it "tests mergestring" do
    expect(Yast::Builtins.mergestring(nil, nil)).to eq(nil)
    expect(Yast::Builtins.mergestring([], nil)).to eq(nil)
    expect(Yast::Builtins.mergestring(nil, "")).to eq(nil)

    expect(Yast::Builtins.mergestring([], "")).to eq("")
    expect(Yast::Builtins.mergestring(["A", "B", "C"], "")).to eq("ABC")
    expect(Yast::Builtins.mergestring(["A", "B", "C"], " ")).to eq("A B C")

    expect(Yast::Builtins.mergestring(["a", "b", "c", "d"], " ")).to eq("a b c d")
    expect(Yast::Builtins.mergestring(["ABC"], "abc")).to eq("ABC")
    expect(Yast::Builtins.mergestring(["a", "", "", "a"], " ")).to eq("a   a")

    # tests from Yast documentation
    expect(Yast::Builtins.mergestring(["", "abc", "dev", "ghi"], "/")).to eq("/abc/dev/ghi")
    expect(Yast::Builtins.mergestring(["abc", "dev", "ghi", ""], "/")).to eq("abc/dev/ghi/")
    expect(Yast::Builtins.mergestring([1, "a", 3], ".")).to eq("1.a.3")
    expect(Yast::Builtins.mergestring(["1", "a", "3"], ".")).to eq("1.a.3")
    expect(Yast::Builtins.mergestring([], ".")).to eq("")
    expect(Yast::Builtins.mergestring(["abc", "dev", "ghi"], "")).to eq("abcdevghi")
    expect(Yast::Builtins.mergestring(["abc", "dev", "ghi"], "123")).to eq("abc123dev123ghi")
  end

  it "tests regexpmatch" do
    expect(Yast::Builtins.regexpmatch(nil, nil)).to eq(nil)
    expect(Yast::Builtins.regexpmatch("", nil)).to eq(nil)
    expect(Yast::Builtins.regexpmatch("", "")).to eq(true)
    expect(Yast::Builtins.regexpmatch("abc", "")).to eq(true)

    expect(Yast::Builtins.regexpmatch("abc", "^a")).to eq(true)
    expect(Yast::Builtins.regexpmatch("abc", "c$")).to eq(true)
    expect(Yast::Builtins.regexpmatch("abc", "^[^][%]bc$")).to eq(true)
  end

  it "tests regexppos" do
    expect(Yast::Builtins.regexppos(nil, nil)).to eq(nil)
    expect(Yast::Builtins.regexppos("", "")).to eq([0, 0])

    # from Yast documentation
    expect(Yast::Builtins.regexppos("abcd012efgh345", "[0-9]+")).to eq([4, 3])
    expect(Yast::Builtins.regexppos("aaabbb", "[0-9]+")).to eq([])
  end

  it "tests regexpsub" do
    expect(Yast::Builtins.regexpsub(nil, nil, nil)).to eq(nil)

    # from Yast documentation
    expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e")).to eq("s_aaab_e")
    expect(Yast::Builtins.regexpsub("aaabbb", "(.*ba)", "s_\\1_e")).to eq(nil)

    #from sysconfig remove whitespaces
    expect(Yast::Builtins.regexpsub(" lest test\tsrst\t", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("lest test\tsrst")
    expect(Yast::Builtins.regexpsub("", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("")
    expect(Yast::Builtins.regexpsub("  \t  ", "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$", "\\1")).to eq("")

    # the result must be UTF-8 string
    expect(Yast::Builtins.regexpsub("aaabbb", "(.*ab)", "s_\\1_e").encoding).to eq(Encoding::UTF_8)
  end

  it "tests regexptokenize" do
    expect(Yast::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*")).to eq(["aaabbB"])
    expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ab)(.*)")).to eq(["aaab", "bb"])
    expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*")).to eq([])
    expect(Yast::Builtins.regexptokenize("aaabbb", "(.*ba).*(")).to eq(nil)

    # the result must be UTF-8 string
    expect(Yast::Builtins.regexptokenize("aaabbBb", "(.*[A-Z]).*").first.encoding).to eq(Encoding::UTF_8)
  end

  it "tests tohexstring" do
    expect(Yast::Builtins.tohexstring(nil)).to eq(nil)
    expect(Yast::Builtins.tohexstring(nil, nil)).to eq(nil)
    expect(Yast::Builtins.tohexstring(0)).to eq("0x0")
    expect(Yast::Builtins.tohexstring(10)).to eq("0xa")
    expect(Yast::Builtins.tohexstring(255)).to eq("0xff")
    expect(Yast::Builtins.tohexstring(222222)).to eq("0x3640e")

    expect(Yast::Builtins.tohexstring(31, 0)).to eq("0x1f")
    expect(Yast::Builtins.tohexstring(31, 1)).to eq("0x1f")
    expect(Yast::Builtins.tohexstring(31, 4)).to eq("0x001f")
    expect(Yast::Builtins.tohexstring(31, 6)).to eq("0x00001f")

    expect(Yast::Builtins.tohexstring(31, -1)).to eq("0x1f")
    expect(Yast::Builtins.tohexstring(31, -3)).to eq("0x1f ")

    expect(Yast::Builtins.tohexstring(-3)).to eq("0xfffffffffffffffd")
    expect(Yast::Builtins.tohexstring(-3, 5)).to eq("0xfffffffffffffffd")
    expect(Yast::Builtins.tohexstring(-3, 18)).to eq("0x00fffffffffffffffd")
    expect(Yast::Builtins.tohexstring(-3, 22)).to eq("0x000000fffffffffffffffd")

    expect(Yast::Builtins.tohexstring(-3, -16)).to eq("0xfffffffffffffffd")
    expect(Yast::Builtins.tohexstring(-3, -17)).to eq("0xfffffffffffffffd ")
    expect(Yast::Builtins.tohexstring(-3, -22)).to eq("0xfffffffffffffffd      ")
  end

  it "tests timestring" do
    expect(Yast::Builtins.timestring(nil, nil, nil)).to eq(nil)

    # disabled: system dependent (depends on the current system time zone),
    # fails if the current offset is not UTC+2:00
    # expect(Yast::Builtins.timestring("%c", 1367839796, false)).to eq("Mon May  6 13:29:56 2013")
    expect(Yast::Builtins.timestring("%c", 1367839796, true)).to eq("Mon May  6 11:29:56 2013")
    expect(Yast::Builtins.timestring("%Y%m%d", 1367839796, false)).to eq("20130506")
  end

  it "tests tolower" do
    expect(Yast::Builtins.tolower(nil)).to eq(nil)
    expect(Yast::Builtins.tolower("")).to eq("")
    expect(Yast::Builtins.tolower("abc")).to eq("abc")
    expect(Yast::Builtins.tolower("ABC")).to eq("abc")
    expect(Yast::Builtins.tolower("ABCÁÄÖČ")).to eq("abcÁÄÖČ")
  end

  it "tests toupper" do
    expect(Yast::Builtins.toupper(nil)).to eq(nil)
    expect(Yast::Builtins.toupper("")).to eq("")
    expect(Yast::Builtins.toupper("ABC")).to eq("ABC")
    expect(Yast::Builtins.toupper("abc")).to eq("ABC")
    expect(Yast::Builtins.toupper("abcáäöč")).to eq("ABCáäöč")
  end

  it "tests toascii" do
    expect(Yast::Builtins.toascii(nil)).to eq(nil)
    expect(Yast::Builtins.toascii("")).to eq("")
    expect(Yast::Builtins.toascii("abc123XYZ")).to eq("abc123XYZ")
    expect(Yast::Builtins.toascii("áabcě123čXYZŽž")).to eq("abc123XYZ")
  end

  it "tests size" do
    expect(Yast::Builtins.size(nil)).to eq(nil)
    expect(Yast::Builtins.size([])).to eq(0)
    expect(Yast::Builtins.size({})).to eq(0)
    expect(Yast::Builtins.size("")).to eq(0)

    expect(Yast::Builtins.size(Yast::Term.new(:HBox))).to eq(0)
    expect(Yast::Builtins.size(Yast::Term.new(:HBox, "test"))).to eq(1)
    expect(Yast::Builtins.size(Yast::Term.new(:HBox, "test", "test"))).to eq(2)
    expect(Yast::Builtins.size(Yast::Term.new(:HBox, Yast::Term.new(:VBox, "test", "test")))).to eq(1)
  end

  it "tests time" do
    expect(Yast::Builtins.time > 0).to be_true
  end

  it "tests find string" do
    expect(Yast::Builtins.find(nil, nil)).to eq(nil)
    expect(Yast::Builtins.find("", nil)).to eq(nil)

    expect(Yast::Builtins.find("", "")).to eq(0)
    expect(Yast::Builtins.find("1234", "3")).to eq(2)
    expect(Yast::Builtins.find("1234", "3")).to eq(2)
    expect(Yast::Builtins.find("1234", "9")).to eq(-1)
  end

  it "tests find list" do
    test_list = [2,3,4]
    expect(Yast::Builtins.find(nil) {|i| next true }).to eq(nil)
    expect(Yast::Builtins.find(test_list) {|i| next true }).to eq(2)
    expect(Yast::Builtins.find(test_list) {|i| next i>2 }).to eq(3)
  end

  it "tests contains" do
    expect(Yast::Builtins.contains(nil, nil)).to eq(nil)
    expect(Yast::Builtins.contains([], nil)).to eq(nil)
    expect(Yast::Builtins.contains(nil, "")).to eq(nil)

    expect(Yast::Builtins.contains([], "")).to eq(false)
    expect(Yast::Builtins.contains(["A", "B", "C"], "")).to eq(false)
    expect(Yast::Builtins.contains(["A", "B", "C"], "X")).to eq(false)
    expect(Yast::Builtins.contains(["A", "B", "C"], "B")).to eq(true)
  end

  it "tests merge" do
    expect(Yast::Builtins.merge(nil, nil)).to eq(nil)
    expect(Yast::Builtins.merge([], nil)).to eq(nil)
    expect(Yast::Builtins.merge(nil, [])).to eq(nil)

    expect(Yast::Builtins.merge([], [])).to eq([])
    expect(Yast::Builtins.merge(["A"], [])).to eq(["A"])
    expect(Yast::Builtins.merge(["A"], ["B"])).to eq(["A", "B"])
    expect(Yast::Builtins.merge(["A"], [1])).to eq(["A", 1])
  end

  it "tests sort" do
    expect(Yast::Builtins.sort(nil)).to eq(nil)

    expect(Yast::Builtins.sort([])).to eq([])
    expect(Yast::Builtins.sort(["A"])).to eq(["A"])
    expect(Yast::Builtins.sort(["Z", "A"])).to eq(["A", "Z"])
    expect(Yast::Builtins.sort([3, 2, 1])).to eq([1, 2, 3])

    expect(Yast::Builtins.sort(["10", 1, 2, 10, 20, "15", 200, 5])).to eq([1, 2, 5, 10, 20, 200, "10", "15"])

    expect(Yast::Builtins.sort([10,1,20]){ |x,y| x>y }).to eq([20,10,1])
  end

  it "tests toset" do
    expect(Yast::Builtins.toset(nil)).to eq(nil)

    expect(Yast::Builtins.toset([])).to eq([])
    expect(Yast::Builtins.toset(["A"])).to eq(["A"])
    expect(Yast::Builtins.toset(["Z", "A"])).to eq(["A", "Z"])
    expect(Yast::Builtins.toset([3, 2, 2, 1, 2, 1, 3, 1, 3, 3])).to eq([1, 2, 3])

    expect(Yast::Builtins.toset([1, 5, 3, 2, 3, true, false, true])).to eq([false, true, 1, 2, 3, 5])
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
    [ Yast::Path.new(".etc.syconfig.\"-arg\""), ".etc.syconfig.\"-arg\""],
    [ Yast::Term.new(:id,["test",:lest]), "`id ([\"test\", `lest])"],
    [ { :test => "data" }, "$[`test:\"data\"]"]
  ]

  it "tests tostring" do
    TOSTRING_TEST_DATA.each do |input,result|
      expect(Yast::Builtins.tostring(input)).to eq(result)
    end
  end

  it "tests tostring with precision" do
    expect(Yast::Builtins.tostring(1.453, 1)).to eq("1.5")
  end

  it "tests change" do
    a = [1,2]
    expect(Yast::Builtins.change(a,3)).to eq([1,2,3])
    expect(a).to eq([1,2])

    h = { :a => 1, :b => 2 }
    res = Yast::Builtins.change(h, :c, 3)
    expect(res).to eq({:a => 1, :b => 2, :c => 3})
    expect(h).to eq(({:a => 1, :b => 2}))
  end

  it "tests isempty" do
    expect(Yast::Builtins.isempty(nil)).to eq(nil)
    expect(Yast::Builtins.isempty([])).to eq(true)
    expect(Yast::Builtins.isempty({})).to eq(true)
    expect(Yast::Builtins.isempty("")).to eq(true)
    expect(Yast::Builtins.isempty([1])).to eq(false)
    expect(Yast::Builtins.isempty({"a" => "b"})).to eq(false)
    expect(Yast::Builtins.isempty("foo")).to eq(false)
  end

  it "tests srandom" do
    expect(Yast::Builtins.srandom() > 0).to be_true
    expect(Yast::Builtins.srandom(10)).to eq(nil)
  end

  it "tests tointeger()" do
    expect(Yast::Builtins.tointeger(nil)).to eq(nil)
    expect(Yast::Builtins.tointeger("")).to eq(nil)
    expect(Yast::Builtins.tointeger("foo")).to eq(nil)
    expect(Yast::Builtins.tointeger(120)).to eq(120)
    expect(Yast::Builtins.tointeger("120")).to eq(120)
    expect(Yast::Builtins.tointeger("  120asdf")).to eq(120)
    expect(Yast::Builtins.tointeger(120.0)).to eq(120)
    expect(Yast::Builtins.tointeger("0x20")).to eq(32)
    expect(Yast::Builtins.tointeger(" 0x20")).to eq(0)
    expect(Yast::Builtins.tointeger("0x20Z")).to eq(32)
    expect(Yast::Builtins.tointeger("010")).to eq(8)
    expect(Yast::Builtins.tointeger("-10")).to eq(-10)

    # weird Yast cases
    expect(Yast::Builtins.tointeger("-0x20")).to eq(0)
    expect(Yast::Builtins.tointeger(" 0x20")).to eq(0)
    expect(Yast::Builtins.tointeger(" 020")).to eq(20)
    expect(Yast::Builtins.tointeger("-020")).to eq(-20)
    expect(Yast::Builtins.tointeger("-0020")).to eq(-20)
  end

  it "tests search" do
    expect(Yast::Builtins.search(nil, nil)).to eq(nil)
    expect(Yast::Builtins.search("", nil)).to eq(nil)

    expect(Yast::Builtins.search("", "")).to eq(0)
    expect(Yast::Builtins.search("1234", "3")).to eq(2)
    expect(Yast::Builtins.search("1234", "3")).to eq(2)
    expect(Yast::Builtins.search("1234", "9")).to eq(nil)
  end

  it "tests haskey" do
    expect(Yast::Builtins.haskey(nil, nil)).to eq(nil)
    expect(Yast::Builtins.haskey({}, nil)).to eq(nil)
    expect(Yast::Builtins.haskey(nil, "")).to eq(nil)

    expect(Yast::Builtins.haskey({}, "")).to eq(false)
    expect(Yast::Builtins.haskey({"a" => 1}, "a")).to eq(true)
    expect(Yast::Builtins.haskey({"a" => 1}, "b")).to eq(false)
  end

  it "tests lookup" do
    expect(Yast::Builtins.lookup({}, nil, nil)).to eq(nil)
    expect(Yast::Builtins.lookup({}, "", nil)).to eq(nil)
    expect(Yast::Builtins.lookup({"a" => 1}, "a", 2)).to eq(1)
    expect(Yast::Builtins.lookup({"a" => 1}, "b", 2)).to eq(2)
  end

  it "tests filter list" do
    expect(Yast::Builtins.filter(nil)).to eq(nil)
    expect(Yast::Builtins.filter([2,3,4]) {|i| next true }).to eq([2,3,4])
    expect(Yast::Builtins.filter([2,3,4]){ |i| next i>3 }).to eq([4])
    expect(Yast::Builtins.filter([2,3,4]){ |i| next i>4 }).to eq([])
  end

  it "tests filter map" do
    test_hash = {2=>3,3=>4}
    expect(Yast::Builtins.filter(test_hash) {|i,j| next true }).to eq(Hash[2=>3,3=>4])
    expect(Yast::Builtins.filter(test_hash){ |i,j| next i>2 }).to eq(Hash[3=>4])
    expect(Yast::Builtins.filter(test_hash){ |i,j| next i>4 }).to eq(Hash.new)
  end

  it "tests each list" do
    expect(Yast::Builtins.foreach(nil){|i| next 5}).to eq(nil)
    list = [2,3,4]
    cycle_detect = 0
    res = Yast::Builtins.foreach(list) do |l|
      cycle_detect += 1
      next l
    end
    expect(res).to eq(4)
    expect(cycle_detect).to eq(3)
    cycle_detect = 0
    res = Yast::Builtins.foreach(list) do |l|
      cycle_detect += 1
      raise Yast::Break if l == 3
    end
    expect(res).to eq(nil)
    expect(cycle_detect).to eq(2)
    cycle_detect = 0
    res = Yast::Builtins.foreach(list) do |l|
      cycle_detect += 1
      next l+3
    end
    expect(res).to eq(7)
    expect(cycle_detect).to eq(3)
  end

  it "tests each map" do
    map = {2=>3,3=>4}
    cycle_detect = 0
    res = Yast::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      next k
    end
    expect(res).to eq(3)
    expect(cycle_detect).to eq(2)
    cycle_detect = 0
    res = Yast::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      raise Yast::Break if k == 2
    end
    expect(res).to eq(nil)
    expect(cycle_detect).to eq(1)
    cycle_detect = 0
    res = Yast::Builtins.foreach(map) do |k,v|
      cycle_detect += 1
      next v+3
    end
    expect(res).to eq(7)
    expect(cycle_detect).to eq(2)
  end

  it "tests maplist list" do
    expect(Yast::Builtins.maplist(nil){|i| next 5}).to eq(nil)

    list = [2,3,4]
    res = Yast::Builtins.maplist(list) do |l|
      next l
    end
    expect(res).to eq([2,3,4])

    res = Yast::Builtins.maplist(list) do |l|
      raise Yast::Break if l == 3
      l
    end
    expect(res).to eq([2])

    res = Yast::Builtins.maplist(list) do |l|
      next if l == 3
      next l+3
    end
    expect(res).to eq([5,nil,7])
  end

  it "tests remove list" do
    list = [0,1,2,3]

    expect(Yast::Builtins.remove(nil,2)).to eq(nil)

    expect(Yast::Builtins.remove(list,2)).to eq([0,1,3])

    expect(Yast::Builtins.remove(list,5)).to eq([0,1,2,3])
    expect(Yast::Builtins.remove(list,-1)).to eq([0,1,2,3])
  end

  it "tests remove map" do
    list = {0 => 1, 2 => 3}

    expect(Yast::Builtins.remove(nil,2)).to eq(nil)

    expect(Yast::Builtins.remove(list,2)).to eq(Hash[0 => 1])
    expect(list).to eq(Hash[ 0 => 1, 2 => 3])

    expect(Yast::Builtins.remove(list,5)).to eq(Hash[ 0 => 1, 2 => 3])
  end

  it "tests remove term" do
    term = Yast::Term.new :t, :a, :b

    expect(Yast::Builtins.remove(term,2)).to eq(Yast::Term.new(:t,:a))
    expect(term).to eq(Yast::Term.new(:t,:a,:b))

    expect(Yast::Builtins.remove(term,5)).to eq(Yast::Term.new(:t,:a,:b))
    expect(Yast::Builtins.remove(term,-1)).to eq(Yast::Term.new(:t,:a,:b))
  end

  it "tests select" do
    list = [0,1,2]
    expect(Yast::Builtins.select(list,1,-1)).to eq 1
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
  it "tests union list" do
    UNION_TESTDATA.each do |first,second,result|
      expect(Yast::Builtins.union(first, second)).to eq(result)
    end
  end

  it "tests float abs" do
    expect(Yast::Builtins::Float.abs(nil)).to eq(nil)

    expect(Yast::Builtins::Float.abs(-5.4)).to eq(5.4)
  end

  it "tests float ceil" do
    expect(Yast::Builtins::Float.ceil(nil)).to eq(nil)

    expect(Yast::Builtins::Float.ceil(-5.4)).to eq(-5.0)

    expect(Yast::Builtins::Float.ceil(5.4)).to eq(6.0)
    expect(Yast::Builtins::Float.ceil(5.4).class).to eq(Float)
  end

  it "tests float floor" do
    expect(Yast::Builtins::Float.floor(nil)).to eq(nil)

    expect(Yast::Builtins::Float.floor(-5.4)).to eq(-6.0)

    expect(Yast::Builtins::Float.floor(5.4)).to eq(5.0)
    expect(Yast::Builtins::Float.floor(5.4).class).to eq(Float)
  end

  it "tests float pow" do
    expect(Yast::Builtins::Float.pow(nil,10.0)).to eq(nil)

    expect(Yast::Builtins::Float.pow(10.0,3.0)).to eq(1000.0)
    expect(Yast::Builtins::Float.pow(10.0,3.0).class).to eq(Float)
  end

  it "tests float trunc" do
    expect(Yast::Builtins::Float.trunc(nil)).to eq(nil)

    expect(Yast::Builtins::Float.trunc(-5.4)).to eq(-5.0)

    expect(Yast::Builtins::Float.trunc(5.6)).to eq(5.0)
    expect(Yast::Builtins::Float.trunc(5.4).class).to eq(Float)
  end

  TOFLOAT_TESTDATA = [
   [ 1, 1.0 ],
   [ nil, nil],
   [ "42", 42.0],
   [ "89.3", 89.3 ],
   [ "test", 0.0 ],
   [ :test, nil ]
  ]
  it "tests tofloat" do
    TOFLOAT_TESTDATA.each do |value,result|
      expect(Yast::Builtins.tofloat(value)).to eq(result)
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
  it "tests flatten" do
    FLATTEN_TESTDATA.each do |value,result|
      expect(Yast::Builtins.flatten(value)).to eq(result)
    end
  end

  it "tests list reduce 1param" do
    list = [0,1,2,3,2,1,-5]
    res = Yast::Builtins::List.reduce(list) do |x,y|
      next x>y ? x : y
    end

    expect(res).to eq(3)

    res = Yast::Builtins::List.reduce(list) do |x,y|
      next x + y
    end
    expect(res).to eq(4)

    expect(Yast::Builtins::List.reduce([]) { |x,y| next x }).to eq(nil)
    expect(Yast::Builtins::List.reduce(nil) { |x,y| next x }).to eq(nil)
  end

  it "tests list reduce 2params" do
    list = [0,1,2,3,2,1,-5]
    res = Yast::Builtins::List.reduce(15,list) do |x,y|
      next x>y ? x : y
    end

    expect(res).to eq(15)

    res = Yast::Builtins::List.reduce(15,list) do |x,y|
      next x + y
    end

    expect(res).to eq(19)

    expect(Yast::Builtins::List.reduce(5,[]) { |x,y| next x }).to eq(5)
    expect(Yast::Builtins::List.reduce(nil,nil) { |x,y| next x }).to eq(nil)
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
  it "tests list swap" do
    SWAP_TESTDATA.each do |list,offset1,offset2,result|
      list_prev = list.nil? ? nil : list.dup 
      expect(Yast::Builtins::List.swap(list, offset1, offset2)).to eq(result)
      #check that list is not modified
      expect(list).to eq(list_prev)
    end
  end

  it "tests listmap" do
    expect(Yast::Builtins.listmap(nil) {|i| next {i => i}}).to eq(nil)

    expect(Yast::Builtins.listmap([1,2]) {|i| next {i => i}}).to eq(Hash[1=>1,2=>2])

  end

  PREPEND_TESTDATA = [
    [nil,5,nil],
    [[0,1],5,[5,0,1]],
    [[1,2],nil,[nil,1,2]],
  ]
  it "tests prepend" do
    PREPEND_TESTDATA.each do |list,element,result|
      list_prev = list.nil? ? nil : list.dup 
      expect(Yast::Builtins.prepend(list, element)).to eq(result)
      #check that list is not modified
      expect(list).to eq(list_prev)
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
  it "tests sublist with len" do
    SUBLIST_TEST_DATA_WITH_LEN.each do |list,offset,length,result|
      list_prev = list.nil? ? nil : list.dup 
      expect(Yast::Builtins.sublist(list, offset, length)).to eq(result)
      #check that list is not modified
      expect(list).to eq(list_prev)
    end 
  end

  SUBLIST_TEST_DATA_WITHOUT_LEN = [
    [nil,1,nil],
    [[0,1],nil,nil],
    [[0,1],2,nil],
    [[0,1],0,[0,1]],
    [[0,1],1,[1]],
  ]
  it "tests sublist without len" do
    SUBLIST_TEST_DATA_WITHOUT_LEN.each do |list,offset,result|
      list_prev = list.nil? ? nil : list.dup 
      expect(Yast::Builtins.sublist(list, offset)).to eq(result)
      #check that list is not modified
      expect(list).to eq(list_prev)
    end 
  end

  it "tests mapmap" do
    expect(Yast::Builtins.listmap(nil) {|k,v| next {v => k}}).to eq(nil)

    expect(Yast::Builtins.mapmap({2=>1,4=>3}) {|k,v| next {v => k}}).to eq(Hash[1=>2,3=>4])

    res = Yast::Builtins.mapmap({2=>1,4=>3}) do |k,v|
      raise Yast::Break if k == 4
      next {v => k}
    end

    expect(res).to eq Hash[1=>2]
  end

  it "tests random" do
    expect(Yast::Builtins.random(nil)).to be_nil

    # there is quite nice chance with this repetition to test even border or range
    100.times do
      expect((0..9).include? Yast::Builtins.random(10)).to be_true
    end
  end

  it "tests topath" do
    expect(Yast::Builtins.topath(nil)).to eq(nil)

    expect(Yast::Builtins.topath(Yast::Path.new(".etc"))).to eq(Yast::Path.new(".etc"))

    expect(Yast::Builtins.topath(".etc")).to eq(Yast::Path.new(".etc"))

    expect(Yast::Builtins.topath("etc")).to eq(Yast::Path.new(".etc"))
  end
  it "tests sformat" do
    expect(Yast::Builtins.sformat(nil)).to eq(nil)
    expect(Yast::Builtins.sformat("test")).to eq("test")
    expect(Yast::Builtins.sformat("test %1")).to eq("test %1")
    expect(Yast::Builtins.sformat("test%a","lest")).to eq("test")
    expect(Yast::Builtins.sformat("test%%","lest")).to eq("test%")
    expect(Yast::Builtins.sformat("test%3%2%1",1,2,3)).to eq("test321")

    expect(Yast::Builtins.sformat("test %1","lest")).to eq("test lest")

    expect(Yast::Builtins.sformat("test %1",:lest)).to eq("test `lest")
  end


  FINDFIRSTOF_TESTDATA = [
    [nil,"ab",nil],
    ["ab",nil,nil],
    ["aaaaa","z",nil],
    ["abcdefg","cxdv",2],
    ["\s\t\n","\s",0],
    ["\s\t\n","\n",2]
  ]
  it "tests findfirstof" do
    FINDFIRSTOF_TESTDATA.each do |string,chars,result|
      expect(Yast::Builtins.findfirstof(string,chars)).to eq(result)
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
  it "tests findfirstnotof" do
    FINDFIRSTNOTOF_TESTDATA.each do |string,chars,result|
      expect(Yast::Builtins.findfirstnotof(string,chars)).to eq(result)
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
  it "tests findlastof" do
    FINDLASTOF_TESTDATA.each do |string,chars,result|
      expect(Yast::Builtins.findlastof(string,chars)).to eq(result)
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
  it "tests findlastnotof" do
    FINDLASTNOTOF_TESTDATA.each do |string,chars,result|
      expect(Yast::Builtins.findlastnotof(string,chars)).to eq(result)
    end
  end

  it "tests float tolstring" do
    old_lang = ENV["LANG"]
    ENV["LANG"] = "cs_CZ.utf-8"
    ret = Yast::Builtins::Float.tolstring(0.52,1)
    expect(ret).to eq("0,5")
    expect(ret.encoding).to eq(Encoding::UTF_8)
    ENV["LANG"] = old_lang
  end

  it "tests crypt" do
    # crypt is salted so cannot reproduce, just test if run and returns something useful
    ["", "md5", "blowfish", "sha256", "sha512"].each do |suffix|
      res = Yast::Builtins.send(:"crypt#{suffix}", "test")
      expect(res).to be_true
      expect(res.size).to be > 10
    end
  end

  it "tests lsort" do
    expect(Yast::Builtins.lsort(["c", "b", "a"])).to eq(["a", "b", "c"])
    expect(Yast::Builtins.lsort([3, 2, 1])).to eq([1, 2, 3])
    expect(Yast::Builtins.lsort([3, "a", 2, "b", 1])).to eq([1, 2, 3, "a", "b"])
    expect(Yast::Builtins.lsort(["a", 50, "z", true])).to eq([true, 50, "a", "z"])
  end

  EVAL_TEST_DATA = [
    [nil, nil],
    [5, 5],
    [ Proc.new() { "15" }, "15"],
  ]

  it "tests eval" do
    EVAL_TEST_DATA.each do |input, result|
      expect(Yast::Builtins.eval(input)).to eq(result)
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

  it "tests deletechars" do
    DELETECHARS_TEST_DATA.each do |input1, input2, result|
      expect(Yast::Builtins.deletechars(input1, input2)).to eq(result)
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

  it "tests filterchars" do
    FILTERCHARS_TEST_DATA.each do |input1, input2, result|
      expect(Yast::Builtins.filterchars(input1, input2)).to eq(result)
    end
  end

  TOTERM_TEST_DATA = [
    [ "test", Yast::Term.new(:test) ],
    [ :test, Yast::Term.new(:test) ],
    [ [:test, [:lest, :srst]], Yast::Term.new(:test, :lest, :srst) ],
    [ Yast::Term.new(:test), Yast::Term.new(:test) ],
  ]

  it "tests toterm" do
    TOTERM_TEST_DATA.each do |input, res|
      expect(Yast::Builtins.toterm(*input)).to eq(res)
    end
  end

  it "tests multiset union" do
    expect(Yast::Builtins::Multiset.union([1,2],[2,3])).to eq([1,2,3])
  end

  it "tests multiset includes" do
    expect(Yast::Builtins::Multiset.includes([1,2],[2,3])).to eq(false)
    expect(Yast::Builtins::Multiset.includes([1,2],[2,2])).to eq(false)
    expect(Yast::Builtins::Multiset.includes([1,2],[2])).to eq(true)
  end

  it "tests multiset difference" do
    expect(Yast::Builtins::Multiset.difference([1,2],[2,3])).to eq([1])
  end

  it "tests multiset symmetric difference" do
    expect(Yast::Builtins::Multiset.symmetric_difference([1,2],[2,3])).to eq([1,3])
    expect(Yast::Builtins::Multiset.symmetric_difference([1,2],[2,2])).to eq([1,2])
    expect(Yast::Builtins::Multiset.symmetric_difference([1,1,2],[2,2,2])).to eq([1,1,2,2])
  end

  it "tests multiset intersection" do
    expect(Yast::Builtins::Multiset.intersection([1,2],[2,3])).to eq([2])
    expect(Yast::Builtins::Multiset.intersection([1,2,2],[2,2,3])).to eq([2,2])
  end

  it "tests multiset union" do
    expect(Yast::Builtins::Multiset.union([1,2],[2,3])).to eq([1,2,3])
    expect(Yast::Builtins::Multiset.union([1,2,2],[2,2,3])).to eq([1,2,2,3])
  end

  it "tests multiset merge" do
    expect(Yast::Builtins::Multiset.merge([1,2],[2,3])).to eq([1,2,2,3])
    expect(Yast::Builtins::Multiset.merge([1,2,2],[2,2,3])).to eq([1,2,2,2,2,3])
    expect(Yast::Builtins::Multiset.merge([2,1,2],[2,3,2])).to eq([2,1,2,2,3,2])
  end

  it "tests deep copy" do
    a = [[1,2],[2,3]]
    b = Yast.deep_copy a
    b[0][0] = 10
    expect(a[0][0]).to eq(1)
    expect(b[0][0]).to eq(10)
  end
end
