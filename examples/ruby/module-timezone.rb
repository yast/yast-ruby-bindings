require 'ycp'
require 'ycp/timezone'

zonemap = YCP::Timezone::get_zonemap
puts zonemap.class
zonemap.each do | element |
  element.each do | key, value |
    value.each do | k, v |
      puts "#{k} #{v}"
    end
  end
end
