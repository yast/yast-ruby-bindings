# encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/convert"
require "ycp/path"
require "ycp/term"

class OpsTest < YCP::TestCase
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
      assert_equal result, YCP::Convert.convert(object, :from => from, :to => to), "Cannot convert from #{object.inspect} '#{from}' to '#{to}'"
    end
  end
end
