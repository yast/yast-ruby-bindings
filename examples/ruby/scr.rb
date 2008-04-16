require 'yast'
require 'ycp/scr'

modules = YCP::SCR::read(".proc.modules")
modules.each do | k, v |
  puts "#{k}:"
  v.each do | a, b |
    puts "    #{a} - #{b}"
  end
end
