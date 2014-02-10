#
# Test Ycp.import
#

require_relative "test_helper_test_unit"

require "yast"

module Yast
  class IncludeTest < Module
    def initialize
      @test = 5
      Yast.include self, "example.rb"
    end

    attr_reader :test
  end
  IT = IncludeTest.new

  class DoubleIncludeTest < Module
    def initialize
      Yast.include self, "example.rb"
      @test = 5
      # second include should not call again init, so @test is kept to 5
      Yast.include self, "example.rb"
    end

    attr_reader :test
  end
  DIT = DoubleIncludeTest.new
end


class IncludeTest < Yast::TestCase
  def setup
    include_path = File.expand_path("../include",__FILE__)+'/'
    Yast.add_include_path include_path
  end

  def test_include
    assert_equal 15, Yast::IT.test
  end

  def test_included_method_call
    assert_equal 20, Yast::IT.test_plus_five
  end

  def test_double_include
    assert_equal 5, Yast::DIT.test
  end
end
