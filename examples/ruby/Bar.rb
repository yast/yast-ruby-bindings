require 'yast'

module Bar
  def self.try
    m = YaST::Module.new("SCR")
    return m.Execute(".target.bash", "firefox").class.to_s
  end
end
