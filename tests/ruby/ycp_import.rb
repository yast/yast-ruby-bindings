#
# Test Ycp.import
#

$:.unshift "../../build/src/ruby"
$:.unshift "../../src/ruby"
ENV["Y2DIR"] = File.dirname(__FILE__)

require 'test/unit'
require 'ycp'

class YcpTest < Test::Unit::TestCase
  def test_import
    assert YCP
    # testing explicit import of ycp module
    # see also module-arch.rb
    assert YCP.import( "Arch" )
    YCP.each_symbol("Arch") do |sym,cat|
      puts "Arch::#{sym}"
    end
  end
end
