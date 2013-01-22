$:.unshift "../../build/src/ruby" # ycpx.so
$:.unshift "../../src/ruby"       # ycp.rb
ENV["Y2DIR"] = File.dirname(__FILE__)

require 'test/unit'

module YCP
  TestCase = Test::Unit::TestCase
end
