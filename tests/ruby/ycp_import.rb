#
# Test Ycp.import
#

$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require 'ycp'

class YcpImportTest < YCP::TestCase
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
