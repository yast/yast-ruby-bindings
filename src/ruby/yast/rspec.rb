require 'yast/rspec/scr'
require 'yast/rspec/shortcuts'

RSpec.configure do |c|
  c.include Yast::RSpec::Shortcuts
  c.include Yast::RSpec::SCR
end
