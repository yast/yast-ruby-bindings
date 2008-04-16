require 'ycp'
require 'ycp/scr'

module Bar
  def self.try
    m = YaST::SCR
    return m.execute(".target.bash", "firefox").class.to_s
  end
end
