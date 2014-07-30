#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/ops"
require "yast/convert"
require "yast/path"
require "yast/term"

describe "Yast::OpsTest" do
  it "tests comparison int" do
    expect(Yast::Ops.less_than(1,2)).to eq(true)
    expect(Yast::Ops.less_or_equal(1,1)).to eq(true)
    expect(Yast::Ops.greater_than(3,2)).to eq(true)
    expect(Yast::Ops.greater_or_equal(2,2)).to eq(true)
    expect(Yast::Ops.less_than(2,2)).to eq(false)
    expect(Yast::Ops.less_or_equal(2,1)).to eq(false)
    expect(Yast::Ops.greater_than(2,2)).to eq(false)
    expect(Yast::Ops.greater_or_equal(2,3)).to eq(false)
  end

  it "tests comparison float" do
    expect(Yast::Ops.less_than(1.0,1.1)).to eq(true)
    expect(Yast::Ops.less_or_equal(1.0,1.0)).to eq(true)
    expect(Yast::Ops.greater_than(2.1,2.0)).to eq(true)
    expect(Yast::Ops.greater_or_equal(2.0,2.0)).to eq(true)
    expect(Yast::Ops.less_than(2.0,2.0)).to eq(false)
    expect(Yast::Ops.less_or_equal(1.1,1.0)).to eq(false)
    expect(Yast::Ops.greater_than(2.0,2.0)).to eq(false)
    expect(Yast::Ops.greater_or_equal(2.0,2.1)).to eq(false)
  end

  it "properly compare between int and float" do
    expect(Yast::Ops.less_than(1,1.1)).to eq(true)
    expect(Yast::Ops.less_than(1.1,1)).to eq(false)
    expect(Yast::Ops.greater_than(44.5, 10000)).to eq(false)
  end

  it "tests comparison string" do
    expect(Yast::Ops.less_than("s","sa")).to eq(true)
    expect(Yast::Ops.less_or_equal("s","s")).to eq(true)
    expect(Yast::Ops.greater_than("ta","t")).to eq(true)
    expect(Yast::Ops.greater_or_equal("t","t")).to eq(true)
    expect(Yast::Ops.less_than("t","t")).to eq(false)
    expect(Yast::Ops.less_or_equal("sa","s")).to eq(false)
    expect(Yast::Ops.greater_than("t","t")).to eq(false)
    expect(Yast::Ops.greater_or_equal("t","ta")).to eq(false)
  end

  it "tests comparison symbols" do
    expect(Yast::Ops.less_than(:s,:sa)).to eq(true)
    expect(Yast::Ops.less_or_equal(:s,:s)).to eq(true)
    expect(Yast::Ops.greater_than(:ta,:t)).to eq(true)
    expect(Yast::Ops.greater_or_equal(:t,:t)).to eq(true)
    expect(Yast::Ops.less_than(:t,:t)).to eq(false)
    expect(Yast::Ops.less_or_equal(:sa,:s)).to eq(false)
    expect(Yast::Ops.greater_than(:t,:t)).to eq(false)
    expect(Yast::Ops.greater_or_equal(:t,:ta)).to eq(false)
  end

  it "tests comparison booleans" do
    expect(Yast::Ops.less_than(false,true)).to eq(true)
    expect(Yast::Ops.less_or_equal(false,false)).to eq(true)
    expect(Yast::Ops.greater_than(true,false)).to eq(true)
    expect(Yast::Ops.greater_or_equal(false,false)).to eq(true)
    expect(Yast::Ops.less_than(false,false)).to eq(false)
    expect(Yast::Ops.less_or_equal(true,false)).to eq(false)
    expect(Yast::Ops.greater_than(false,false)).to eq(false)
    expect(Yast::Ops.greater_or_equal(false,true)).to eq(false)
  end

  it "tests comparison list" do
    expect(Yast::Ops.less_than([1],[1,2])).to eq(true)
    expect(Yast::Ops.less_than([1,1],[2])).to eq(true)
    expect(Yast::Ops.less_than([nil,nil,5],[nil,2])).to eq(true)
    expect(Yast::Ops.less_or_equal([1,1],[2])).to eq(true)
    expect(Yast::Ops.less_than([1,2],[1])).to eq(false)
    expect(Yast::Ops.less_than([2],[1,1])).to eq(false)
    expect(Yast::Ops.less_than([nil,5],[nil,nil,2])).to eq(false)
    expect(Yast::Ops.less_or_equal([2],[1,1])).to eq(false)
  end

  it "tests comparison term" do
    expect(Yast::Ops.less_than(Yast::Term.new(:a),Yast::Term.new(:b))).to eq(true)
    expect(Yast::Ops.less_than(Yast::Term.new(:a,1,2),Yast::Term.new(:a,1,3))).to eq(true)
    expect(Yast::Ops.less_than(Yast::Term.new(:a,1,2),Yast::Term.new(:b,1,1))).to eq(true)
    expect(Yast::Ops.less_than(Yast::Term.new(:b),Yast::Term.new(:a))).to eq(false)
  end

  it "tests comparison path" do
    expect(Yast::Ops.less_than(Yast::Path.new('.'),Yast::Path.new('.etc'))).to eq(true)
    expect(Yast::Ops.less_than(Yast::Path.new('.etca'),Yast::Path.new('.etcb'))).to eq(true)
    expect(Yast::Ops.less_than(Yast::Path.new('.etc.a'),Yast::Path.new('.etca'))).to eq(true)
  end

  it "tests comparison nil" do
    expect(Yast::Ops.less_than(1,nil)).to eq(nil)
    expect(Yast::Ops.less_or_equal(1,nil)).to eq(nil)
    expect(Yast::Ops.greater_than(3,nil)).to eq(nil)
    expect(Yast::Ops.greater_or_equal(2,nil)).to eq(nil)
    expect(Yast::Ops.less_than(nil,2)).to eq(nil)
    expect(Yast::Ops.less_or_equal(nil,1)).to eq(nil)
    expect(Yast::Ops.greater_than(nil,2)).to eq(nil)
    expect(Yast::Ops.greater_or_equal(nil,3)).to eq(nil)
  end

  it "tests comparison mixture" do
    expect(Yast::Ops.less_than(1,Yast::Term.new(:b))).to eq(true)
    expect(Yast::Ops.less_than("s",Yast::Term.new(:a,1,3))).to eq(true)
    expect(Yast::Ops.less_than(:a,Yast::Term.new(:b,1,1))).to eq(true)
    expect(Yast::Ops.less_than({ :a => "b"},Yast::Term.new(:b))).to eq(false)
    expect(Yast::Ops.less_than({"a" => 1, 1 => 2},{"a" => 1, "b" => 2})).to eq(true)
  end

  describe "Ops.get" do
    it "tests get map" do
      map = { "a" => { "b" => "c" }}
      expect(Yast::Ops.get(map,"a","n")).to eq({ "b" => "c"})
      expect(Yast::Ops.get(map,["a","b"],"n")).to eq("c")
      expect(Yast::Ops.get(map,["a","c"],"n")).to eq("n")
      expect(Yast::Ops.get(map,["c","b"],"n")).to eq("n")
      expect(Yast::Ops.get(map,["c","b"]){ "n" }).to eq("n")
    end

    it "tests get list" do
      list = [["a","b"]]
      expect(Yast::Ops.get(list,0,"n")).to eq(["a","b"])
      expect(Yast::Ops.get(list,[0,1],"n")).to eq("b")
      expect(Yast::Ops.get(list,[0,2],"n")).to eq("n")
      expect(Yast::Ops.get(list,[1,1],"n")).to eq("n")
    end

    it "tests get term" do
      term = Yast::Term.new(:a,"a","b")
      expect(Yast::Ops.get(term,1,"n")).to eq("b")
      expect(Yast::Ops.get(term,[2],"n")).to eq("n")
    end

    it "tests get mixture" do
      map_list =  { "a" => ["b","c"]}
      expect(Yast::Ops.get(map_list,["a",1],"n")).to eq("c")
      expect(Yast::Ops.get(map_list,["a",2],"n")).to eq("n")
      map_term =  { "a" => Yast::Term.new(:a,"b","c")}
      expect(Yast::Ops.get(map_term,["a",1],"n")).to eq("c")
      expect(Yast::Ops.get(map_term,["a",2],"n")).to eq("n")
    end

    it "tests get corner cases" do
      list = ["a"]
      expect(Yast::Ops.get(list,["a"],"n")).to eq("n")
      expect(Yast::Ops.get(list,[0,0],"n")).to eq("n")
    end
  end

  describe "Ops.get_foo shortcuts" do
    let(:list) { ["a","b"] }

    it "gets a matching type" do
      expect(Yast::Ops.get_string(list,0,"n")).to eq("a")
    end

    it "nils a mismatching type" do
      expect(Yast::Ops.get_integer(list,0,"n")).to eq(nil)
    end

    it "warns when the container is nil" do
      any_frame = kind_of(Integer)
      expect(Yast).to receive(:y2milestone).with(any_frame, /called on nil/)
      Yast::Ops.get_string(nil, 0, "n")
    end

    it "reports the right location when warning" do
      # The internal method that sees the file is:
      # y2_logger(log_level, component, file, line, method, format, args)
      line = __LINE__ + 3 # this must be the line where get_string is called
      expect(Yast).to receive(:y2_logger).
        with(kind_of(Integer), "Ruby", __FILE__, line, //, //)
      Yast::Ops.get_string(nil, 0, "n")
    end
  end

  it "tests set" do
    l = nil
    Yast::Ops.set(l,[1,2],5)
    expect(l).to be_nil

    l = [1,2]
    Yast::Ops.set(l,nil,5)
    expect(l).to eq [1,2]

    Yast::Ops.set(l,[2],3)
    expect(l).to eq [1,2,3]

    l = [1,2]
    Yast::Ops.set(l,[1],[])
    expect(l).to eq [1,[]]

    Yast::Ops.set(l,[1,1],5)
    expect(l).to eq([1,[nil,5]])

    l = {5=>2,4=>[]}
    Yast::Ops.set(l, [4,1],5)
    expect(l).to eq(Hash[5=>2,4=>[nil,5]])

    l = {5=>2,4=>[]}
    Yast::Ops.set(l, [5,2],5)
    expect(l).to eq(Hash[5=>2,4=>[]])

    l = Yast::Term.new(:a,:b)
    Yast::Ops.set(l, 0, :c)
    expect(l).to eq(Yast::Term.new(:a, :c))
    Yast::Ops.set(l, 1, :b)
    expect(l).to eq(Yast::Term.new(:a, :c, :b))
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

  it "tests add" do
    ADD_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.add(first,second)).to eq(result)
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

  it "tests subtract" do
    SUBTRACT_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.subtract(first,second)).to eq(result)
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

  it "tests multiply" do
    MULTIPLY_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.multiply(first,second)).to eq(result)
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

  it "tests divide" do
    DIVIDE_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.divide(first,second)).to eq(result)
    end
  end

#test case format is [value1,value2,result]
  MODULO_TESTCASES = [
    [nil,1,nil],
    [1,nil,nil],
    [nil,nil,nil],
    [5,2,1],
  ]

  it "tests modulo" do
    MODULO_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.modulo(first,second)).to eq(result)
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

  it "tests bitwise and" do
    BITWISE_AND_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.bitwise_and(first,second)).to eq(result)
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

  it "tests bitwise or" do
    BITWISE_OR_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.bitwise_or(first,second)).to eq(result)
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

  it "tests bitwise xor" do
    BITWISE_XOR_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.bitwise_xor(first,second)).to eq(result)
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

  it "tests shift left" do
    SHIFT_LEFT_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.shift_left(first,second)).to eq(result)
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

  it "tests shift right" do
    SHIFT_RIGHT_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.shift_right(first,second)).to eq(result)
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

  it "tests logical and" do
    LOGICAL_AND_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.logical_and(first,second)).to eq(result)
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

  it "tests logical or" do
    LOGICAL_OR_TESTCASES.each do |first,second,result|
      expect(Yast::Ops.logical_or(first,second)).to eq(result)
    end
  end

#test case format is [value,result]
  UNARY_MINUS_TESTCASES = [
    [nil,nil],
    [1,-1],
    [5.5,-5.5],
  ]

  it "tests unary minus" do
    UNARY_MINUS_TESTCASES.each do |value,result|
      expect(Yast::Ops.unary_minus(value)).to eq(result)
    end
  end

#test case format is [value,result]
  LOGICAL_NOT_TESTCASES = [
    [nil,nil],
    [true,false],
    [false,true],
  ]

  it "tests logical not" do
    LOGICAL_NOT_TESTCASES.each do |value,result|
      expect(Yast::Ops.logical_not(value)).to eq(result)
    end
  end

#test case format is [value,result]
  BITWISE_NOT_TESTCASES = [
    [nil,nil],
    [5,-6],
    [8589934592,-8589934593],
    [-558589934592,558589934591]
  ]

  it "tests bitwise not" do
    BITWISE_NOT_TESTCASES.each do |value,result|
      expect(Yast::Ops.bitwise_not(value)).to eq(result)
    end
  end

  it "tests is" do
    expect(Yast::Ops.is("t", "string")).to be true
    expect(Yast::Ops.is("t", "integer")).to be false
  end

  it "tests is shortcut" do
    expect(Yast::Ops.is_string?("t")).to be true
    expect(Yast::Ops.is_void?("t")).to be false
  end
end
