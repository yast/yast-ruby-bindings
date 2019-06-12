#!/usr/bin/env ruby
# typed: true

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
  puts "Test skipped."
  exit true
end

RESULT = "/tmp/exit".freeze
OUTPUT = "/tmp/test_cmd_output".freeze

def cleanup
  [RESULT, OUTPUT].each do |file|
    File.delete(file) if File.exist?(file)
  end
end

test = File.dirname(__FILE__) + "/std_streams_spec.rb"
cmd = "rspec #{test} >#{OUTPUT} 2>&1"

`tmux -c '#{cmd}; echo \$? > #{RESULT}'`
if File.exist?(RESULT) && File.read(RESULT) == "0\n"
  puts "Test succeeded."
  cleanup
  exit true
else
  puts "Test failed: '#{cmd}'."
  if File.exist?(OUTPUT)
    puts "Output was:"
    puts File.read(OUTPUT)
  end
  cleanup
  exit false
end
