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
end
