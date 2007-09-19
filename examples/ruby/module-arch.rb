require 'yast'

m = YaST::Module.new("Arch")
puts m.sparc32
puts m.arch_short
puts m.is_xen
