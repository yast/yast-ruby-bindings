# typed: true
ROOT_DIR = File.expand_path("../..", __FILE__)
BINARY_PATH = "#{ROOT_DIR}/build/src/binary"
RUBY_INC_PATH = "#{ROOT_DIR}/src/ruby"
require "fileutils"
if !File.exist? "#{BINARY_PATH}/yast"
  FileUtils.ln_s BINARY_PATH, "#{BINARY_PATH}/yast" # to load builtinx.so
end
if !File.exist? "#{BINARY_PATH}/plugin"
  # to load py2lang_ruby.so for calling testing ruby clients
  FileUtils.ln_s BINARY_PATH, "#{BINARY_PATH}/plugin"
end
$LOAD_PATH.unshift BINARY_PATH # yastx.so
$LOAD_PATH.unshift RUBY_INC_PATH # yast.rb
ENV["Y2DIR"] = BINARY_PATH + ":" + File.dirname(__FILE__) + "/test_module"
