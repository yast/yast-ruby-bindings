#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper_rspec"

require "yast/convert"
require "yast/path"
require "yast/term"

describe "OpsTest" do
  # data description [object, from, to, result]
  CONVERT_TESTDATA = [
    [nil,'any','integer',nil],
    [nil,'any','term',nil],
    [nil,'any','path',nil],
    [5,'any','string',nil],
    [5,'integer','string',nil],
    [5,'integer','string',nil],
    [5,'any','integer',5],
    [5.5,'any','integer',5],
    [5.9,'any','integer',5],
    [5,'any','float',5.0],
  ]

  it "tests convert" do
    CONVERT_TESTDATA.each do |object,from,to,result|
      expect(Yast::Convert.convert(object, :from => from, :to => to)).to eq(result)
    end
  end

  it "tests shortcuts" do
    expect(Yast::Convert.to_string("t")).to eq("t")
  end
end
