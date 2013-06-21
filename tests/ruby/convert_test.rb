# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "yast/convert"
require "yast/path"
require "yast/term"

class OpsTest < Yast::TestCase
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

  def test_convert
    CONVERT_TESTDATA.each do |object,from,to,result|
      assert_equal result, Yast::Convert.convert(object, :from => from, :to => to), "Cannot convert from #{object.inspect} '#{from}' to '#{to}'"
    end
  end

  def test_shortcuts
    assert_equal "t", Yast::Convert.to_string("t")
  end
end
