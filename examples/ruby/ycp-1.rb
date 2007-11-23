require 'ycp'
include Ycpx

f = File.new('/usr/share/YaST2/modules/Arch.ycp')
p = Parser.new( f.fileno, 'Arch')
puts p.class
y = p.parse
puts y.methods
y.is_block
