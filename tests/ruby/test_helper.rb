ROOT_DIR = File.expand_path('../../..',__FILE__)
$:.unshift File.expand_path("#{ROOT_DIR}/build/src/binary",__FILE__) # ycpx.so
$:.unshift File.expand_path("#{ROOT_DIR}/src/ruby",__FILE__)       # ycp.rb
ENV["Y2DIR"] = File.dirname(__FILE__)

require 'test/unit'

module YCP
  TestCase = Test::Unit::TestCase
end
