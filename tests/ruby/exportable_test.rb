$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require 'ycp/exportable'

module Test
  include YCP::Exportable
  publish :variable => :variable_a, :type => "map<symbol,any>"
  self.variable_a = { :test => "lest" }

  publish :method => :test, :type => "string(integer,term)"
  def self.test(a,b)
    return "test"
  end
end

class ExportableTest < YCP::TestCase
  def test_publish_methods
    assert_equal [:test], Test.published_methods.keys
    assert_equal "string(integer,term)", Test.published_methods[:test].type
  end

  def test_publish_variables
    assert_equal [:variable_a], Test.published_variables.keys
    assert_equal "map<symbol,any>", Test.published_variables[:variable_a].type
  end

  def test_variable_definition
    Test.variable_a = ({ :a => 15 })
    assert_equal ({:a => 15}), Test.variable_a
  end
end
