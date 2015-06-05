ROOT_DIR = File.expand_path("../../..", __FILE__)
binary_path = "#{ROOT_DIR}/build/src/binary"
require "fileutils"
if !File.exist? "#{binary_path}/yast"
  FileUtils.ln_s binary_path, "#{binary_path}/yast" # to load builtinx.so
end
if !File.exist? "#{binary_path}/plugin"
  FileUtils.ln_s binary_path, "#{binary_path}/plugin" # to load py2lang_ruby.so for calling testing ruby clients
end
$LOAD_PATH.unshift binary_path # yastx.so
$LOAD_PATH.unshift "#{ROOT_DIR}/src/ruby"       # yast.rb
ENV["Y2DIR"] = binary_path + ":" + File.dirname(__FILE__) + "/test_module"
