require "yast/rspec/helpers"
require "yast/rspec/matchers"
require "yast/rspec/scr"
require "yast/rspec/shortcuts"

RSpec.configure do |c|
  c.include Yast::RSpec::Shortcuts
  c.include Yast::RSpec::SCR
  c.include Yast::RSpec::Matchers
end
