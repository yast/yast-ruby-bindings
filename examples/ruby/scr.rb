require 'yast'

m = YaST::Module.new("SCR")
modules = m.Read(".proc.modules")
modules.each do | k, v |
  puts "#{k}:"
  v.each do | a, b |
    puts "    #{a} - #{b}"
  end
end