$LOAD_PATH << File.dirname(__FILE__)
require "test_helper"

require "ycp/path"

class PathTest < YCP::TestCase
  def test_initialize
    assert_equal ".etc", YCP::Path.new(".etc").to_s
    assert_equal '."et?c"', YCP::Path.new('."et?c"').to_s
  end

  def test_load_from_string
    assert_equal ".\"etc\"", YCP::Path.from_string("etc").to_s
    assert_equal '."et?c"', YCP::Path.from_string('et?c').to_s
  end

  def test_add
    root = YCP::Path.new '.'
    etc = YCP::Path.new '.etc'
    sysconfig = YCP::Path.new '.sysconfig'
    assert_equal ".etc.sysconfig", (etc + sysconfig).to_s
    assert_equal '.etc."sysconfig"', (etc + 'sysconfig').to_s
    assert_equal '.', (root+root).to_s
    assert_equal '.etc', (root+etc).to_s
    assert_equal '.etc', (etc+root).to_s
  end

  def test_equals
    assert_equal YCP::Path.new(".\"\x1a\""), YCP::Path.new(".\"\x1A\"")
    assert_equal YCP::Path.new(".\"\x41\""), YCP::Path.new(".\"A\"")
    assert_not_equal YCP::Path.new(".\"\""), YCP::Path.new('.')
  end

  def test_comparison
    assert_equal true, YCP::Path.new('.ba') >= YCP::Path.new('."a?"')
    assert_equal true, YCP::Path.new('."b?"') >= YCP::Path.new('.ab')
  end

  def test_clone
    etc = YCP::Path.new '.etc.sysconfig.DUMP'
    assert_equal '.etc.sysconfig.DUMP', etc.clone.to_s

  end
end
