require 'uri'
module URI
  # URI::parse works even without glue

  def self.scheme(instance)
    instance.scheme
  end

  # garbage_collect
  class << self;
    include GC
  end
end
