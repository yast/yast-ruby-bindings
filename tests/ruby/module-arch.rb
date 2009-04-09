#
# Test Arch.ycp
#

$:.unshift "../../build/src/ruby" # ycpx.so
$:.unshift "../../src/ruby"       # ycp.rb

require 'test/unit'

class ArchTest < Test::Unit::TestCase
  def test_arch
    require 'ycp'
    # testing implicit import of ycp module
    # see also ycp_import.rb
    require 'ycp/arch'
    puts YCP::Arch::sparc32
    puts YCP::Arch::arch_short
    puts YCP::Arch::is_xen
  end
end
