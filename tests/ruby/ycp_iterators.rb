#
# Test Ycp.each_symbol
#

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require 'ycp'

class YcpTest < YCP::TestCase
  def test_each_symbol
    puts "\ntest_each_symbol\n"
    YCP.each_symbol("Arch") do |sym,cat|
      puts "Ycp symbol #{sym}, category #{cat}"
    end
    assert true
  end
end
