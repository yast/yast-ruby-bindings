#
# Test Arch.ycp
#
$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require 'ycp'

class ArchTest < YCP::TestCase
  def test_arch
    # testing implicit import of ycp module
    # see also ycp_import.rb
    YCP.import 'Arch'
    puts YCP::Arch::sparc32
    puts YCP::Arch::arch_short
    puts YCP::Arch::is_xen
  end
end
