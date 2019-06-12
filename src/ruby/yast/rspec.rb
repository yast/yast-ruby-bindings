# typed: false
require "yast/rspec/scr"
require "yast/rspec/shortcuts"
require "yast/rspec/matchers"

RSpec.configure do |c|
  c.include Yast::RSpec::Shortcuts
  c.include Yast::RSpec::SCR
  c.include Yast::RSpec::Matchers
end
