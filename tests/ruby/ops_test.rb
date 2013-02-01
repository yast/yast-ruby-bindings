# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/ops"
require "ycp/path"
require "ycp/term"

class YCP::OpsTest < YCP::TestCase
  #Testing source for all this test is ops.ycp in test directory used to verify any behavior

  SAME_VALUES = [
    [ nil,                   nil ],
    [ 1  ,                   1 ],
    [ 1.1,                   1.1 ],
    [ "s",                   "s" ],
    [ :s ,                   :s ],
    [ false,                 false ],
    [ [1],                   [1] ],
    [ { 1 => 2 },            { 1 => 2} ],
    [ YCP::Path.new("."),    YCP::Path.new(".") ],
    [ YCP::Term.new(:a, :b), YCP::Term.new(:a, :b)],
  ]
  def test_equal_same
    SAME_VALUES.each do |first,second|
      assert YCP::Ops.equal(first, second), "Value should be same, but differs \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_same
    SAME_VALUES.each do |first,second|
      assert !YCP::Ops.not_equal(first, second), "Value is same, but marked as not equal \n-#{first.inspect}\n+#{second.inspect}"
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
    [ YCP::Path.new("."),    YCP::Path.new(".etc") ],
    [ YCP::Term.new(:a, :b), YCP::Term.new(:a)],
  ]
  def test_equal_different_value
    DIFFERENT_VALUES.each do |first,second|
      assert !YCP::Ops.equal(first, second), "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_different_value
    DIFFERENT_VALUES.each do |first,second|
      assert YCP::Ops.not_equal(first, second), "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_equal_with_nil
    DIFFERENT_VALUES.each do |first,second|
      assert !YCP::Ops.equal(first, nil), "Value should differs from nil, but marked as same \n-#{first.inspect}"
      assert !YCP::Ops.equal(nil,second), "Nil should differ from value, but marked as same \n+#{second.inspect}"
    end
  end

  def test_comparison_int
    assert_equal true, YCP::Ops.less_than(1,2)
    assert_equal true, YCP::Ops.less_or_equal(1,1)
    assert_equal true, YCP::Ops.greater_than(3,2)
    assert_equal true, YCP::Ops.greater_or_equal(2,2)
    assert_equal false, YCP::Ops.less_than(2,2)
    assert_equal false, YCP::Ops.less_or_equal(2,1)
    assert_equal false, YCP::Ops.greater_than(2,2)
    assert_equal false, YCP::Ops.greater_or_equal(2,3)
  end

  def test_comparison_float
    assert_equal true, YCP::Ops.less_than(1.0,1.1)
    assert_equal true, YCP::Ops.less_or_equal(1.0,1.0)
    assert_equal true, YCP::Ops.greater_than(2.1,2.0)
    assert_equal true, YCP::Ops.greater_or_equal(2.0,2.0)
    assert_equal false, YCP::Ops.less_than(2.0,2.0)
    assert_equal false, YCP::Ops.less_or_equal(1.1,1.0)
    assert_equal false, YCP::Ops.greater_than(2.0,2.0)
    assert_equal false, YCP::Ops.greater_or_equal(2.0,2.1)
  end

  def test_comparison_string
    assert_equal true, YCP::Ops.less_than("s","sa")
    assert_equal true, YCP::Ops.less_or_equal("s","s")
    assert_equal true, YCP::Ops.greater_than("ta","t")
    assert_equal true, YCP::Ops.greater_or_equal("t","t")
    assert_equal false, YCP::Ops.less_than("t","t")
    assert_equal false, YCP::Ops.less_or_equal("sa","s")
    assert_equal false, YCP::Ops.greater_than("t","t")
    assert_equal false, YCP::Ops.greater_or_equal("t","ta")
  end

  def test_comparison_symbols
    assert_equal true, YCP::Ops.less_than(:s,:sa)
    assert_equal true, YCP::Ops.less_or_equal(:s,:s)
    assert_equal true, YCP::Ops.greater_than(:ta,:t)
    assert_equal true, YCP::Ops.greater_or_equal(:t,:t)
    assert_equal false, YCP::Ops.less_than(:t,:t)
    assert_equal false, YCP::Ops.less_or_equal(:sa,:s)
    assert_equal false, YCP::Ops.greater_than(:t,:t)
    assert_equal false, YCP::Ops.greater_or_equal(:t,:ta)
  end

  def test_comparison_booleans
    assert_equal true, YCP::Ops.less_than(false,true)
    assert_equal true, YCP::Ops.less_or_equal(false,false)
    assert_equal true, YCP::Ops.greater_than(true,false)
    assert_equal true, YCP::Ops.greater_or_equal(false,false)
    assert_equal false, YCP::Ops.less_than(false,false)
    assert_equal false, YCP::Ops.less_or_equal(true,false)
    assert_equal false, YCP::Ops.greater_than(false,false)
    assert_equal false, YCP::Ops.greater_or_equal(false,true)
  end

  def test_comparison_list
    assert_equal true, YCP::Ops.less_than([1],[1,2])
    assert_equal true, YCP::Ops.less_than([1,1],[2])
    assert_equal true, YCP::Ops.less_than([nil,nil,5],[nil,2])
    assert_equal true, YCP::Ops.less_or_equal([1,1],[2])
    assert_equal false, YCP::Ops.less_than([1,2],[1])
    assert_equal false, YCP::Ops.less_than([2],[1,1])
    assert_equal false, YCP::Ops.less_than([nil,5],[nil,nil,2])
    assert_equal false, YCP::Ops.less_or_equal([2],[1,1])
  end

  def test_comparison_term
    assert_equal true, YCP::Ops.less_than(YCP::Term.new(:a),YCP::Term.new(:b))
    assert_equal true, YCP::Ops.less_than(YCP::Term.new(:a,1,2),YCP::Term.new(:a,1,3))
    assert_equal true, YCP::Ops.less_than(YCP::Term.new(:a,1,2),YCP::Term.new(:b,1,1))
    assert_equal false, YCP::Ops.less_than(YCP::Term.new(:b),YCP::Term.new(:a))
  end

  def test_comparison_path
    assert_equal true, YCP::Ops.less_than(YCP::Path.new('.'),YCP::Path.new('.etc'))
    assert_equal true, YCP::Ops.less_than(YCP::Path.new('.etca'),YCP::Path.new('.etcb'))
    assert_equal true, YCP::Ops.less_than(YCP::Path.new('.etc.a'),YCP::Path.new('.etca'))
  end

  def test_comparison_nil
    assert_equal nil, YCP::Ops.less_than(1,nil)
    assert_equal nil, YCP::Ops.less_or_equal(1,nil)
    assert_equal nil, YCP::Ops.greater_than(3,nil)
    assert_equal nil, YCP::Ops.greater_or_equal(2,nil)
    assert_equal nil, YCP::Ops.less_than(nil,2)
    assert_equal nil, YCP::Ops.less_or_equal(nil,1)
    assert_equal nil, YCP::Ops.greater_than(nil,2)
    assert_equal nil, YCP::Ops.greater_or_equal(nil,3)
  end

  def test_comparison_mixture
    assert_equal true, YCP::Ops.less_than(1,YCP::Term.new(:b))
    assert_equal true, YCP::Ops.less_than("s",YCP::Term.new(:a,1,3))
    assert_equal true, YCP::Ops.less_than(:a,YCP::Term.new(:b,1,1))
    assert_equal false, YCP::Ops.less_than({ :a => "b"},YCP::Term.new(:b))
    assert_equal true, YCP::Ops.less_than({"a" => 1, 1 => 2},{"a" => 1, "b" => 2})
  end

  def test_index_map
    map = { "a" => { "b" => "c" }}
    assert_equal "c", YCP::Ops.index(map,["a","b"],"n")
    assert_equal "n", YCP::Ops.index(map,["a","c"],"n")
    assert_equal "n", YCP::Ops.index(map,["c","b"],"n")
  end

  def test_index_list
    list = [["a","b"]]
    assert_equal "b", YCP::Ops.index(list,[0,1],"n")
    assert_equal "n", YCP::Ops.index(list,[0,2],"n")
    assert_equal "n", YCP::Ops.index(list,[1,1],"n")
  end

  def test_index_term
    term = YCP::Term.new(:a,"a","b")
    assert_equal "b", YCP::Ops.index(term,[1],"n")
    assert_equal "n", YCP::Ops.index(term,[2],"n")
  end

  def test_index_mixture
    map_list =  { "a" => ["b","c"]}
    assert_equal "c", YCP::Ops.index(map_list,["a",1],"n")
    assert_equal "n", YCP::Ops.index(map_list,["a",2],"n")
    map_term =  { "a" => YCP::Term.new(:a,"b","c")}
    assert_equal "c", YCP::Ops.index(map_term,["a",1],"n")
    assert_equal "n", YCP::Ops.index(map_term,["a",2],"n")
  end

  def test_index_corner_cases
    list = ["a"]
    assert_equal "n", YCP::Ops.index(list,["a"],"n")
    assert_equal "n", YCP::Ops.index(list,[0,0],"n")
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
    ["s",YCP::Path.new(".etc"),"s.etc"],
  ]

  def test_add
    ADD_TESTCASES.each do |first,second,result|
      assert_equal result, YCP::Ops.add(first,second)
    end
  end

#test case format is [value1,value2,result]
  SUBSTRACT_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [1,2,-1],
    [1.1,1.1,0.0],
  ]

  def test_substract
    SUBSTRACT_TESTCASES.each do |first,second,result|
      assert_equal result, YCP::Ops.substract(first,second)
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
      assert_equal result, YCP::Ops.multiply(first,second)
    end
  end

#test case format is [value1,value2,result]
  DIVIDE_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [2,1,2],
    [3.0,1.5,2.0],
  ]

  def test_divide
    DIVIDE_TESTCASES.each do |first,second,result|
      assert_equal result, YCP::Ops.divide(first,second)
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
      assert_equal result, YCP::Ops.modulo(first,second)
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
      assert_equal result, YCP::Ops.bitwise_and(first,second)
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
      assert_equal result, YCP::Ops.bitwise_or(first,second)
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
      assert_equal result, YCP::Ops.bitwise_xor(first,second)
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
      assert_equal result, YCP::Ops.shift_left(first,second)
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
      assert_equal result, YCP::Ops.shift_right(first,second)
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
      assert_equal result, YCP::Ops.logical_and(first,second)
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
      assert_equal result, YCP::Ops.logical_or(first,second)
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
      assert_equal result, YCP::Ops.unary_minus(value)
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
      assert_equal result, YCP::Ops.logical_not(value)
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
      assert_equal result, YCP::Ops.bitwise_not(value)
    end
  end


end
