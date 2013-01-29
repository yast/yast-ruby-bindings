# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/ops"
require "ycp/path"
require "ycp/term"

class OpsTest < YCP::TestCase
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
      assert Ops.equal(first, second), "Value should be same, but differs \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_same
    SAME_VALUES.each do |first,second|
      assert !Ops.not_equal(first, second), "Value is same, but marked as not equal \n-#{first.inspect}\n+#{second.inspect}"
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
      assert !Ops.equal(first, second), "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_not_equal_different_value
    DIFFERENT_VALUES.each do |first,second|
      assert Ops.not_equal(first, second), "Value should differs, but mark as same \n-#{first.inspect}\n+#{second.inspect}"
    end
  end

  def test_equal_with_nil
    DIFFERENT_VALUES.each do |first,second|
      assert !Ops.equal(first, nil), "Value should differs from nil, but marked as same \n-#{first.inspect}"
      assert !Ops.equal(nil,second), "Nil should differ from value, but marked as same \n+#{second.inspect}"
    end
  end

  def test_comparison_int
    assert_equal true, Ops.less_than(1,2)
    assert_equal true, Ops.less_or_equal(1,1)
    assert_equal true, Ops.greater_than(3,2)
    assert_equal true, Ops.greater_or_equal(2,2)
    assert_equal false, Ops.less_than(2,2)
    assert_equal false, Ops.less_or_equal(2,1)
    assert_equal false, Ops.greater_than(2,2)
    assert_equal false, Ops.greater_or_equal(2,3)
  end

  def test_comparison_float
    assert_equal true, Ops.less_than(1.0,1.1)
    assert_equal true, Ops.less_or_equal(1.0,1.0)
    assert_equal true, Ops.greater_than(2.1,2.0)
    assert_equal true, Ops.greater_or_equal(2.0,2.0)
    assert_equal false, Ops.less_than(2.0,2.0)
    assert_equal false, Ops.less_or_equal(1.1,1.0)
    assert_equal false, Ops.greater_than(2.0,2.0)
    assert_equal false, Ops.greater_or_equal(2.0,2.1)
  end

  def test_comparison_string
    assert_equal true, Ops.less_than("s","sa")
    assert_equal true, Ops.less_or_equal("s","s")
    assert_equal true, Ops.greater_than("ta","t")
    assert_equal true, Ops.greater_or_equal("t","t")
    assert_equal false, Ops.less_than("t","t")
    assert_equal false, Ops.less_or_equal("sa","s")
    assert_equal false, Ops.greater_than("t","t")
    assert_equal false, Ops.greater_or_equal("t","ta")
  end

  def test_comparison_symbols
    assert_equal true, Ops.less_than(:s,:sa)
    assert_equal true, Ops.less_or_equal(:s,:s)
    assert_equal true, Ops.greater_than(:ta,:t)
    assert_equal true, Ops.greater_or_equal(:t,:t)
    assert_equal false, Ops.less_than(:t,:t)
    assert_equal false, Ops.less_or_equal(:sa,:s)
    assert_equal false, Ops.greater_than(:t,:t)
    assert_equal false, Ops.greater_or_equal(:t,:ta)
  end

  def test_comparison_booleans
    assert_equal true, Ops.less_than(false,true)
    assert_equal true, Ops.less_or_equal(false,false)
    assert_equal true, Ops.greater_than(true,false)
    assert_equal true, Ops.greater_or_equal(false,false)
    assert_equal false, Ops.less_than(false,false)
    assert_equal false, Ops.less_or_equal(true,false)
    assert_equal false, Ops.greater_than(false,false)
    assert_equal false, Ops.greater_or_equal(false,true)
  end

  def test_comparison_list
    assert_equal true, Ops.less_than([1],[1,2])
    assert_equal true, Ops.less_than([1,1],[2])
    assert_equal true, Ops.less_than([nil,nil,5],[nil,2])
    assert_equal true, Ops.less_or_equal([1,1],[2])
    assert_equal false, Ops.less_than([1,2],[1])
    assert_equal false, Ops.less_than([2],[1,1])
    assert_equal false, Ops.less_than([nil,5],[nil,nil,2])
    assert_equal false, Ops.less_or_equal([2],[1,1])
  end

  def test_comparison_nil
    assert_equal nil, Ops.less_than(1,nil)
    assert_equal nil, Ops.less_or_equal(1,nil)
    assert_equal nil, Ops.greater_than(3,nil)
    assert_equal nil, Ops.greater_or_equal(2,nil)
    assert_equal nil, Ops.less_than(nil,2)
    assert_equal nil, Ops.less_or_equal(nil,1)
    assert_equal nil, Ops.greater_than(nil,2)
    assert_equal nil, Ops.greater_or_equal(nil,3)
  end
end
