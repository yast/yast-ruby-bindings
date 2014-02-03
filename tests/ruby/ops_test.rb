# encoding: utf-8

require_relative "test_helper_test_unit"

require "yast/ops"
require "yast/convert"
require "yast/path"
require "yast/term"

class Yast::OpsTest < Yast::TestCase
  #Testing source for all this test is ops.yast in test directory used to verify any behavior

  SAME_VALUES = [
    [ nil,                   nil ],
    [ 1  ,                   1 ],
    [ 1.1,                   1.1 ],
    [ "s",                   "s" ],
    [ :s ,                   :s ],
    [ false,                 false ],
    [ [1],                   [1] ],
    [ { 1 => 2 },            { 1 => 2} ],
    [ Yast::Path.new("."),    Yast::Path.new(".") ],
    [ Yast::Term.new(:a, :b), Yast::Term.new(:a, :b)],
  ]
  def test_equal_same
    SAME_VALUES.each do |first,second|
      assert first == second, "Value should be same, but differs \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_same
    SAME_VALUES.each do |first,second|
      assert first == second, "Value is same, but marked as not equal \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  DIFFERENT_VALUES = [
    [ 1  ,                   2 ],
    [ 1.1,                   1.2 ],
    [ "s",                   "st" ],
    [ :s ,                   :st ],
    [ false,                 true ],
    [ [1],                   [1, 2] ],
    [ { 1 => 2 },            { 1 => 2, 2 => 3 } ],
    [ Yast::Path.new("."),    Yast::Path.new(".etc") ],
    [ Yast::Term.new(:a, :b), Yast::Term.new(:a)],
  ]
  def test_equal_different_value
    DIFFERENT_VALUES.each do |first,second|
      assert first !=  second, "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_different_value
    DIFFERENT_VALUES.each do |first,second|
      assert first != second, "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_equal_with_nil
    DIFFERENT_VALUES.each do |first,second|
      assert first != nil, "Value should differs from nil, but marked as same \n-#{first.inspect}"
      assert nil != second, "Nil should differ from value, but marked as same \n+#{second.inspect}"
    end
  end

  def test_comparison_int
    assert_equal true, Yast::Ops.less_than(1,2)
    assert_equal true, Yast::Ops.less_or_equal(1,1)
    assert_equal true, Yast::Ops.greater_than(3,2)
    assert_equal true, Yast::Ops.greater_or_equal(2,2)
    assert_equal false, Yast::Ops.less_than(2,2)
    assert_equal false, Yast::Ops.less_or_equal(2,1)
    assert_equal false, Yast::Ops.greater_than(2,2)
    assert_equal false, Yast::Ops.greater_or_equal(2,3)
  end

  def test_comparison_float
    assert_equal true, Yast::Ops.less_than(1.0,1.1)
    assert_equal true, Yast::Ops.less_or_equal(1.0,1.0)
    assert_equal true, Yast::Ops.greater_than(2.1,2.0)
    assert_equal true, Yast::Ops.greater_or_equal(2.0,2.0)
    assert_equal false, Yast::Ops.less_than(2.0,2.0)
    assert_equal false, Yast::Ops.less_or_equal(1.1,1.0)
    assert_equal false, Yast::Ops.greater_than(2.0,2.0)
    assert_equal false, Yast::Ops.greater_or_equal(2.0,2.1)
  end

  def test_comparison_string
    assert_equal true, Yast::Ops.less_than("s","sa")
    assert_equal true, Yast::Ops.less_or_equal("s","s")
    assert_equal true, Yast::Ops.greater_than("ta","t")
    assert_equal true, Yast::Ops.greater_or_equal("t","t")
    assert_equal false, Yast::Ops.less_than("t","t")
    assert_equal false, Yast::Ops.less_or_equal("sa","s")
    assert_equal false, Yast::Ops.greater_than("t","t")
    assert_equal false, Yast::Ops.greater_or_equal("t","ta")
  end

  def test_comparison_symbols
    assert_equal true, Yast::Ops.less_than(:s,:sa)
    assert_equal true, Yast::Ops.less_or_equal(:s,:s)
    assert_equal true, Yast::Ops.greater_than(:ta,:t)
    assert_equal true, Yast::Ops.greater_or_equal(:t,:t)
    assert_equal false, Yast::Ops.less_than(:t,:t)
    assert_equal false, Yast::Ops.less_or_equal(:sa,:s)
    assert_equal false, Yast::Ops.greater_than(:t,:t)
    assert_equal false, Yast::Ops.greater_or_equal(:t,:ta)
  end

  def test_comparison_booleans
    assert_equal true, Yast::Ops.less_than(false,true)
    assert_equal true, Yast::Ops.less_or_equal(false,false)
    assert_equal true, Yast::Ops.greater_than(true,false)
    assert_equal true, Yast::Ops.greater_or_equal(false,false)
    assert_equal false, Yast::Ops.less_than(false,false)
    assert_equal false, Yast::Ops.less_or_equal(true,false)
    assert_equal false, Yast::Ops.greater_than(false,false)
    assert_equal false, Yast::Ops.greater_or_equal(false,true)
  end

  def test_comparison_list
    assert_equal true, Yast::Ops.less_than([1],[1,2])
    assert_equal true, Yast::Ops.less_than([1,1],[2])
    assert_equal true, Yast::Ops.less_than([nil,nil,5],[nil,2])
    assert_equal true, Yast::Ops.less_or_equal([1,1],[2])
    assert_equal false, Yast::Ops.less_than([1,2],[1])
    assert_equal false, Yast::Ops.less_than([2],[1,1])
    assert_equal false, Yast::Ops.less_than([nil,5],[nil,nil,2])
    assert_equal false, Yast::Ops.less_or_equal([2],[1,1])
  end

  def test_comparison_term
    assert_equal true, Yast::Ops.less_than(Yast::Term.new(:a),Yast::Term.new(:b))
    assert_equal true, Yast::Ops.less_than(Yast::Term.new(:a,1,2),Yast::Term.new(:a,1,3))
    assert_equal true, Yast::Ops.less_than(Yast::Term.new(:a,1,2),Yast::Term.new(:b,1,1))
    assert_equal false, Yast::Ops.less_than(Yast::Term.new(:b),Yast::Term.new(:a))
  end

  def test_comparison_path
    assert_equal true, Yast::Ops.less_than(Yast::Path.new('.'),Yast::Path.new('.etc'))
    assert_equal true, Yast::Ops.less_than(Yast::Path.new('.etca'),Yast::Path.new('.etcb'))
    assert_equal true, Yast::Ops.less_than(Yast::Path.new('.etc.a'),Yast::Path.new('.etca'))
  end

  def test_comparison_nil
    assert_equal nil, Yast::Ops.less_than(1,nil)
    assert_equal nil, Yast::Ops.less_or_equal(1,nil)
    assert_equal nil, Yast::Ops.greater_than(3,nil)
    assert_equal nil, Yast::Ops.greater_or_equal(2,nil)
    assert_equal nil, Yast::Ops.less_than(nil,2)
    assert_equal nil, Yast::Ops.less_or_equal(nil,1)
    assert_equal nil, Yast::Ops.greater_than(nil,2)
    assert_equal nil, Yast::Ops.greater_or_equal(nil,3)
  end

  def test_comparison_mixture
    assert_equal true, Yast::Ops.less_than(1,Yast::Term.new(:b))
    assert_equal true, Yast::Ops.less_than("s",Yast::Term.new(:a,1,3))
    assert_equal true, Yast::Ops.less_than(:a,Yast::Term.new(:b,1,1))
    assert_equal false, Yast::Ops.less_than({ :a => "b"},Yast::Term.new(:b))
    assert_equal true, Yast::Ops.less_than({"a" => 1, 1 => 2},{"a" => 1, "b" => 2})
  end

  def test_get_map
    map = { "a" => { "b" => "c" }}
    assert_equal({ "b" => "c"}, Yast::Ops.get(map,"a","n"))
    assert_equal "c", Yast::Ops.get(map,["a","b"],"n")
    assert_equal "n", Yast::Ops.get(map,["a","c"],"n")
    assert_equal "n", Yast::Ops.get(map,["c","b"],"n")
    assert_equal "n", Yast::Ops.get(map,["c","b"]){ "n" }
  end

  def test_get_list
    list = [["a","b"]]
    assert_equal(["a","b"], Yast::Ops.get(list,0,"n"))
    assert_equal "b", Yast::Ops.get(list,[0,1],"n")
    assert_equal "n", Yast::Ops.get(list,[0,2],"n")
    assert_equal "n", Yast::Ops.get(list,[1,1],"n")
  end

  def test_get_term
    term = Yast::Term.new(:a,"a","b")
    assert_equal "b", Yast::Ops.get(term,1,"n")
    assert_equal "n", Yast::Ops.get(term,[2],"n")
  end

  def test_get_mixture
    map_list =  { "a" => ["b","c"]}
    assert_equal "c", Yast::Ops.get(map_list,["a",1],"n")
    assert_equal "n", Yast::Ops.get(map_list,["a",2],"n")
    map_term =  { "a" => Yast::Term.new(:a,"b","c")}
    assert_equal "c", Yast::Ops.get(map_term,["a",1],"n")
    assert_equal "n", Yast::Ops.get(map_term,["a",2],"n")
  end

  def test_get_corner_cases
    list = ["a"]
    assert_equal "n", Yast::Ops.get(list,["a"],"n")
    assert_equal "n", Yast::Ops.get(list,[0,0],"n")
  end

  def test_get_shortcuts
    list = ["a","b"]
    assert_equal("a", Yast::Ops.get_string(list,0,"n"))
    assert_equal(nil, Yast::Ops.get_integer(list,0,"n"))
  end

  def test_set
    l = nil
    Yast::Ops.set(l,[1,2],5)
    assert_equal nil,l 
    
    l = [1,2]
    Yast::Ops.set(l,nil,5)
    assert_equal [1,2],l 

    Yast::Ops.set(l,[2],3)
    assert_equal [1,2,3],l

    l = [1,2]
    Yast::Ops.set(l,[1],[])
    assert_equal [1,[]],l 

    Yast::Ops.set(l,[1,1],5)
    assert_equal [1,[nil,5]], l

    l = {5=>2,4=>[]}
    Yast::Ops.set(l, [4,1],5)
    assert_equal Hash[5=>2,4=>[nil,5]], l

    l = {5=>2,4=>[]}
    Yast::Ops.set(l, [5,2],5)
    assert_equal Hash[5=>2,4=>[]], l

    l = Yast::Term.new(:a,:b)
    Yast::Ops.set(l, 0, :c)
    assert_equal Yast::Term.new(:a, :c), l
    Yast::Ops.set(l, 1, :b)
    assert_equal Yast::Term.new(:a, :c, :b), l
  end

#test case format is [value1,value2,result]
  ADD_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [1,2,3],
    [1.2,2.3,3.5],
    [[0],0,[0,0]],
    [[0],[0],[0,0]],
    [[0],[[0]],[0,[0]]],
    [{:a => :b},{:a => :c},{:a => :c}],
    ["s","c","sc"],
    ["s",15,"s15"],
    ["s",:c,"sc"],
    ["s",Yast::Path.new(".etc"),"s.etc"],
  ]

  def test_add
    ADD_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.add(first,second)
    end
  end

#test case format is [value1,value2,result]
  SUBTRACT_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [1,2,-1],
    [1.1,1.1,0.0],
  ]

  def test_subtract
    SUBTRACT_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.subtract(first,second)
    end
  end

#test case format is [value1,value2,result]
  MULTIPLY_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [1,2,2],
    [1.5,2.0,3.0],
  ]

  def test_multiply
    MULTIPLY_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.multiply(first,second)
    end
  end

#test case format is [value1,value2,result]
  DIVIDE_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [2,0,nil], #yes fantastic yast allows division by zero
    [2,1,2],
    [3.0,1.5,2.0],
  ]

  def test_divide
    DIVIDE_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.divide(first,second)
    end
  end

#test case format is [value1,value2,result]
  MODULO_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [5,2,1],
  ]

  def test_modulo
    MODULO_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.modulo(first,second)
    end
  end

#test case format is [value1,value2,result]
  BITWISE_AND_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [5,3,1],
    [5,4,4],
  ]

  def test_bitwise_and
    BITWISE_AND_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.bitwise_and(first,second)
    end
  end

#test case format is [value1,value2,result]
  BITWISE_OR_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [5,3,7],
    [5,4,5],
  ]

  def test_bitwise_or
    BITWISE_OR_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.bitwise_or(first,second)
    end
  end

#test case format is [value1,value2,result]
  BITWISE_XOR_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [5,3,6],
    [5,4,1],
  ]

  def test_bitwise_xor
    BITWISE_XOR_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.bitwise_xor(first,second)
    end
  end

#test case format is [value1,value2,result]
  SHIFT_LEFT_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [1,2,4],
    [2,2,8],
  ]

  def test_shift_left
    SHIFT_LEFT_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.shift_left(first,second)
    end
  end
 
#test case format is [value1,value2,result]
  SHIFT_RIGHT_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [4,2,1],
    [8,2,2],
  ]

  def test_shift_right
    SHIFT_RIGHT_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.shift_right(first,second)
    end
  end

#test case format is [value1,value2,result]
  LOGICAL_AND_TESTCASES = [
    [nil,true,false],
    [true,nil,false],
    [nil,nil,false],
    [true,false,false],
    [true,true,true],
  ]

  def test_logical_and
    LOGICAL_AND_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.logical_and(first,second)
    end
  end

#test case format is [value1,value2,result]
  LOGICAL_OR_TESTCASES = [
    [nil,true,true],
    [true,nil,true],
    [nil,nil,false],
    [true,false,true],
    [true,true,true],
  ]

  def test_logical_or
    LOGICAL_OR_TESTCASES.each do |first,second,result|
      assert_equal result, Yast::Ops.logical_or(first,second)
    end
  end

#test case format is [value,result]
  UNARY_MINUS_TESTCASES = [
    [nil,nil],
    [1,-1],
    [5.5,-5.5],
  ]

  def test_unary_minus
    UNARY_MINUS_TESTCASES.each do |value,result|
      assert_equal result, Yast::Ops.unary_minus(value)
    end
  end

#test case format is [value,result]
  LOGICAL_NOT_TESTCASES = [
    [nil,nil],
    [true,false],
    [false,true],
  ]

  def test_logical_not
    LOGICAL_NOT_TESTCASES.each do |value,result|
      assert_equal result, Yast::Ops.logical_not(value)
    end
  end

#test case format is [value,result]
  BITWISE_NOT_TESTCASES = [
    [nil,nil],
    [5,-6],
    [8589934592,-8589934593],
    [-558589934592,558589934591]
  ]

  def test_bitwise_not
    BITWISE_NOT_TESTCASES.each do |value,result|
      assert_equal result, Yast::Ops.bitwise_not(value)
    end
  end

  def test_is
    assert Yast::Ops.is("t", "string")
    assert !Yast::Ops.is("t", "integer")
  end

  def test_is_shortcut
    assert Yast::Ops.is_string?("t")
    assert !Yast::Ops.is_void?("t")
  end
end
