require 'yast'

m = YaST::Module.new("Storage")
dp = m.GetDiskPartition("/dev/sda1")
dp.each do | key, value |
  puts "#{key} #{value}"
end