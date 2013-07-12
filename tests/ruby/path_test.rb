$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "yast/path"

class PathTest < Yast::TestCase
  def test_initialize
    assert_equal ".etc", Yast::Path.new(".etc").to_s
    assert_equal '."et?c"', Yast::Path.new('.et?c').to_s
  end

  def test_load_from_string
    assert_equal ".\"etc\"", Yast::Path.from_string("etc").to_s
    assert_equal '."et?c"', Yast::Path.from_string('et?c').to_s
  end

  def test_add
    root = Yast::Path.new '.'
    etc = Yast::Path.new '.etc'
    sysconfig = Yast::Path.new '.sysconfig'
    assert_equal ".etc.sysconfig", (etc + sysconfig).to_s
    assert_equal '.etc."sysconfig"', (etc + 'sysconfig').to_s
    assert_equal '.', (root+root).to_s
    assert_equal '.etc', (root+etc).to_s
    assert_equal '.etc', (etc+root).to_s
  end

  def test_equals
    assert_equal Yast::Path.new(".\"\x1a\""), Yast::Path.new(".\"\x1A\"")
    assert_equal Yast::Path.new(".\"\x41\""), Yast::Path.new(".\"A\"")
    assert_not_equal Yast::Path.new(".\"\""), Yast::Path.new('.')
  end

  def test_comparison
    assert_equal true, Yast::Path.new('.ba') >= Yast::Path.new('."a?"')
    assert_equal true, Yast::Path.new('."b?"') >= Yast::Path.new('.ab')
  end

  def test_clone
    etc = Yast::Path.new '.etc.sysconfig.DUMP'
    assert_equal '.etc.sysconfig.DUMP', etc.clone.to_s

  end
end
