require 'yast'

m = YaST::Module.new("Timezone")
zonemap = m.get_zonemap()
puts zonemap.class
zonemap.each do | element |
  element.each do | key, value |
    value.each do | k, v |
      puts "#{k} #{v}"
    end
  end
end
