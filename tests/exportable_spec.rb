#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/exportable"

class MyTestClass
  extend Yast::Exportable
  publish variable: :complex, type: "map< string, map<list, map> >"
  publish variable: :variable_a, type: "map"
  def initialize
    self.variable_a = { test: "lest" }
  end

  publish function: :test, type: "string(integer,term)"
  def test(_a, _b)
    "test"
  end
end

MyTest = MyTestClass.new

describe "ExportableTest" do
  it "tests publish methods" do
    expect(MyTest.class.published_functions).to eq([{name: :test, type: "string(integer,term)"}])
  end

  it "tests publish variables" do
    expect(MyTest.class.published_variables).to match_array([
      {name: :variable_a, type: "map<any,any>"},
      {name: :complex, type: "map<string,map<list<any>,map<any,any>>>"}
    ])
  end

  it "tests variable definition" do
    MyTest.variable_a = ({ a: 15 })
    expect(MyTest.variable_a).to eq(a: 15)
  end
end
