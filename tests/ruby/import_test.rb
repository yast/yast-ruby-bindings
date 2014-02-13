#
# Test Ycp.import
#

require_relative "test_helper_test_unit"

require "yast"

class YcpImportTest < Yast::TestCase
  def test_import
    Yast.import( "ExampleTestModule" )
    assert Yast::ExampleTestModule.respond_to?(:sparc_map)
    assert Yast::ExampleTestModule.respond_to?(:is_xen)
    assert Yast::ExampleTestModule.respond_to?(:arch_short)
    assert Yast::ExampleTestModule.respond_to?(:example_string)
    assert Yast::ExampleTestModule.respond_to?(:example_string=)
  end

  def test_method_call
    Yast.import "ExampleTestModule"
    assert_equal false, Yast::ExampleTestModule.is_xen
    assert_equal "ZX Spectrum", Yast::ExampleTestModule.arch_short
    assert_equal ({"one" => 1, "two" => 2}), Yast::ExampleTestModule.sparc_map
  end
end
