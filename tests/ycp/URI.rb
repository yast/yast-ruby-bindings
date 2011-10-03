require 'uri'
module URI
  # URI::parse works even without glue?
  #def self.parse(uri_string)
    
  #end
  
  def self.scheme(instance)
    instance.scheme
  end
end
