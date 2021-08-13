#!/usr/bin/env ruby

# std_streams_spec.rb is used to verify that bnc#943757 is fixed in
# libyui-ncurses >= 2.47.3. Thus, is an integration test for YaST+libyui
#
# It runs perfectly in a regular system by just calling
#   rspec std_streams_spec.rb
# but headless systems like jenkins need this script to fake the screen

def tmux_available?
  system "which tmux >/dev/null 2>&1"
end

# If tmux is not available, just skip this without failing
if !tmux_available?
  puts "tmux not available, test skipped."
  exit true
end

require "tempfile"
RESULT = Tempfile.new("test_result")
OUTPUT = Tempfile.new("test_output")

test = File.join(__dir__, "std_streams_spec.rb")
cmd = "rspec #{test} >#{OUTPUT.path} 2>&1"

tmux_out = `TERM=screen tmux -c '#{cmd}; echo \$? > #{RESULT.path}'`
puts "Outside tmux output:"
puts tmux_out
if RESULT.read == "0\n"
  puts "Test succeeded."
  exit true
else
  puts "Test failed: '#{cmd}'."
  puts "result: '#{RESULT.read}'"
  puts "Output was:"
  puts OUTPUT.read
  exit false
end
