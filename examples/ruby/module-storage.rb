require 'ycp'
require 'ycp/storage'


puts YCP::Storage.methods

dp = YCP::Storage::GetDiskPartition("/dev/sda1")
dp.each do | key, value |
  puts "#{key} #{value}"
end