$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require 'ycp/exportable'

class MyTestClass
  extend YCP::Exportable
  publish :variable => :complex, :type => "map< string, map<list, map> >"
  publish :variable => :variable_a, :type => "map"
  def initialize
    self.variable_a = { :test => "lest" }
  end

  publish :function => :test, :type => "string(integer,term)"
  def test(a,b)
    return "test"
  end
end

MyTest = MyTestClass.new

class ExportableTest < YCP::TestCase
  def test_publish_methods
    assert_equal [:test], MyTest.class.published_functions.keys
    assert_equal :test, MyTest.class.published_functions.values.first.function
    assert_equal "string(integer,term)", MyTest.class.published_functions[:test].type
  end

  def test_publish_variables
    assert MyTest.class.published_variables[:variable_a]
    assert_equal "map<any,any>", MyTest.class.published_variables[:variable_a].type
  end

  def test_variable_definition
    MyTest.variable_a = ({ :a => 15 })
    assert_equal ({:a => 15}), MyTest.variable_a
  end

  def test_type_full_specification
    assert_equal "map<string,map<list<any>,map<any,any>>>", MyTest.class.published_variables[:complex].type

  end
end
