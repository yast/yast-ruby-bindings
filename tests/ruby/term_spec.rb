require_relative "test_helper_rspec"

require "yast/term"

describe "TermTest" do
  it "tests initialize" do
    expect(Yast::Term.new(:HBox).value).to eq(:HBox)
    expect(Yast::Term.new(:HBox).params).to eq([])
    expect(Yast::Term.new(:HBox, "test").params).to eq(["test"])
    expect(Yast::Term.new(:HBox, "test").params.first).to eq("test")

    expect(Yast::Term.new(:HBox, Yast::Term.new(:VBox)).params.first.value).to eq(:VBox)
  end

  it "tests update" do
    t = Yast::Term.new(:HBox, 1, 2)
    t.params[0] = 0
    expect(t.params.first).to eq(0)
  end

  it "tests equal" do
    expect(Yast::Term.new(:HBox)).to eq(Yast::Term.new(:HBox))
    expect(Yast::Term.new(:VBox)).to_not eq(Yast::Term.new(:HBox))
    expect(Yast::Term.new(:HBox, "test")).to_not eq(Yast::Term.new(:HBox))
  end

  it "tests size" do
    expect(Yast::Term.new(:HBox).size).to eq(0)
    expect(Yast::Term.new(:HBox, "test").size).to eq(1)
    expect(Yast::Term.new(:HBox, "test").size).to eq(1)
    expect(Yast::Term.new(:HBox, Yast::Term.new(:VBox, "test", "test")).size).to eq(1)
  end

end
