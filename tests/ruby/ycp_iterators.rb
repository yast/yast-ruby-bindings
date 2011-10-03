#
# Test Ycp.each_symbol
# Test Ycp.each_builtin_symbol
# Test Ycp.each_builtin
#

$:.unshift "../../build/src/ruby"
$:.unshift "../../src/ruby"
ENV["Y2DIR"] = File.dirname(__FILE__)

require 'test/unit'
require 'ycp'

class YcpTest < Test::Unit::TestCase
  def test_each_symbol
    puts "\ntest_each_symbol\n"
    YCP.each_symbol("Arch") do |sym,cat|
      puts "Ycp symbol #{sym}, category #{cat}"
    end
    assert true
  end
  def test_each_builtin
    puts "\ntest_each_builtin\n"
    YCP.each_builtin do |ns, cat|
      puts "Ycp builtin #{ns}, category #{cat}"
      if cat == :namespace
	YCP.each_builtin_symbol(ns) do |sym, cat|
	  puts "  #{ns}.#{sym}, category #{cat}"
	end
      end
    end
    assert true
  end
  def test_each_builtin_symbol
    puts "\ntest_each_builtin_symbol\n"
    YCP.each_builtin_symbol("float") do |sym, cat|
      puts "Ycp builtin symbol #{sym}, category #{cat}"
    end
    assert true
  end
end
