require_relative "test_helper_rspec"

require "yast/path"

describe "PathTest" do
  it "tests initialize" do
    expect(Yast::Path.new(".etc").to_s).to eq(".etc")
    expect(Yast::Path.new('.et?c').to_s).to eq('."et?c"')
  end

  it "tests load from string" do
    expect(Yast::Path.from_string("etc").to_s).to eq(".\"etc\"")
    expect(Yast::Path.from_string('et?c').to_s).to eq('."et?c"')
  end

  it "tests add" do
    root = Yast::Path.new '.'
    etc = Yast::Path.new '.etc'
    sysconfig = Yast::Path.new '.sysconfig'
    expect((etc + sysconfig).to_s).to eq(".etc.sysconfig")
    expect((etc + 'sysconfig').to_s).to eq('.etc."sysconfig"')
    expect((root+root).to_s).to eq('.')
    expect((root+etc).to_s).to eq('.etc')
    expect((etc+root).to_s).to eq('.etc')
  end

  it "tests equals" do
    expect(Yast::Path.new(".\"\x1A\"")).to eq(Yast::Path.new(".\"\x1a\""))
    expect(Yast::Path.new(".\"A\"")).to eq(Yast::Path.new(".\"\x41\""))
    expect(Yast::Path.new('.')).to_not eq(Yast::Path.new(".\"\""))
  end

  it "tests comparison" do
    expect(Yast::Path.new('.ba')).to be >= Yast::Path.new('."a?"')
    expect(Yast::Path.new('."b?"')).to be >= Yast::Path.new('.ab')
  end

  it "tests clone" do
    etc = Yast::Path.new '.etc.sysconfig.DUMP'
    expect(etc.clone.to_s).to eq('.etc.sysconfig.DUMP')
  end
end
