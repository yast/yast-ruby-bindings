#
# Test Ycp.import
#

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp"

class YcpImportTest < YCP::TestCase
  def setup
    module_path = File.expand_path("../modules",__FILE__)+'/'
    puts module_path
    YCP.add_module_path module_path
  end

  def test_import
    YCP.import( "ExampleTestModule" )
    assert YCP::ExampleTestModule.respond_to?(:sparc_map)
    assert YCP::ExampleTestModule.respond_to?(:is_xen)
    assert YCP::ExampleTestModule.respond_to?(:arch_short)
    assert YCP::ExampleTestModule.respond_to?(:example_string)
    assert YCP::ExampleTestModule.respond_to?(:example_string=)
  end

  def test_method_call
    YCP.import "ExampleTestModule"
    assert_equal false, YCP::ExampleTestModule.is_xen
    assert_equal "ZX Spectrum", YCP::ExampleTestModule.arch_short
    assert_equal ({"one" => 1, "two" => 2}), YCP::ExampleTestModule.sparc_map
  end
end
