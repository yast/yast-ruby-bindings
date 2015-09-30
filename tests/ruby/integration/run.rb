#!/usr/bin/env ruby

# std_streams_spec.rb is used to verify that bnc#943757 is fixed in
# libyui-ncurses >= 2.47.3. Thus, is an integration test for YaST+libyui
#
# It runs perfectly in a regular system by just calling
#   rspec std_streams_spec.rb
# but headless systems like jenkins need this script to fake the screen

test = File.dirname(__FILE__) + "/std_streams_spec.rb"
cmd = "rspec #{test}"

`screen -D -m sh -c '#{cmd}; echo \$? > /tmp/exit'`
if File.read("/tmp/exit") != "0\n"
  puts "Test failed: '#{cmd}'. Rerun manually to see the cause."
  exit false
else
  puts "Test succeeded."
  exit true
end
