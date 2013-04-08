ROOT_DIR = File.expand_path('../../..',__FILE__)
binary_path = "#{ROOT_DIR}/build/src/binary"
require "fileutils"
if !File.exists? "#{binary_path}/ycp"
  FileUtils.ln_s binary_path, "#{binary_path}/ycp" #to load builtinx.so
end
$:.unshift binary_path # ycpx.so
$:.unshift "#{ROOT_DIR}/src/ruby"       # ycp.rb
ENV["Y2DIR"] = File.dirname(__FILE__)

require 'test/unit'

module YCP
  TestCase = Test::Unit::TestCase
end
