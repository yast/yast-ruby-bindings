#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"

require "yast/term"

describe Yast::Term do
  def term(*params)
    Yast::Term.new(*params)
  end

  describe ".new" do
    context "with single parameter" do
      it "sets value to parameter" do
        expect(term(:HBox).value).to eq(:HBox)
      end

      it "have empty params" do
        expect(term(:HBox).params).to eq([])
      end
    end

    context "with more parameters" do
      it "set all parameters except first one to params array" do
        expect(term(:HBox, "test").params).to eq(["test"])
      end
    end
  end

  describe "#[]=" do
    it "updates inplace parameters" do
      t = term(:HBox, 1, 2)
      t.params[0] = 0
      expect(t.params.first).to eq(0)
    end
  end

  describe "#[]" do
    it "returns elements from params on given index" do
      t = term(:HBox, 1, 2)
      expect(t.params[0]).to eq(1)
    end
  end

  describe "#<<" do             #  " <- unconfuse Emacs string highlighting
    it "appends parameter to params" do
      t = term(:HBox, 1, 2)
      t << 3
      expect(t[2]).to eq(3)
    end
  end

  describe "#<=> (comparison)" do
    it "if value and params are equal, then it is equal terms" do
      expect(term(:HBox)).to eq(term(:HBox))
    end

    it "if value are different then terms are not equal" do
      expect(term(:VBox)).to_not eq(term(:HBox))
    end

    it "if params are different then terms are not equal" do
      expect(term(:HBox, "test")).to_not eq(term(:HBox))
    end

    it "if value are different then it compare value for comparison" do
      expect(term(:VBox)).to be > term(:HBox)
    end

    it "if value is equal, then use params to comparison" do
      expect(term(:HBox, "test")).to be > term(:HBox)
    end

    it "if non-term, then uncomparable" do
      expect(term(:HBox, "test") <=> 42).to eq nil
    end
  end

  describe "#size" do
    it "returns size of params" do
      expect(term(:HBox).size).to eq(0)
      expect(term(:HBox, "test").size).to eq(1)
      expect(term(:HBox, term(:VBox, "test", "test")).size).to eq(1)
    end
  end

  describe "#empty?" do
    it "returns if params are empty" do
      expect(term(:HBox).empty?).to eq(true)
      expect(term(:HBox, "test").empty?).to eq(false)
    end
  end

  describe "Enumerable" do
    it "includes enumerable module that iterate over params" do
      t = term(:HBox, 1, 2, 3)

      expect(t).to include(1)
      expect(t.first).to eq(1)

      expect(t.max).to eq(3)

      nested = term(:HBox, term(:InputField, term(:id, "ID")))

      widget = nested.find do |t|
        t.include?(term(:id, "ID"))
      end

      expect(widget.value).to eq :InputField
    end
  end

  describe "#nested_find" do
    it "returns object passing block even if it is deep in nested terms" do
      nested = term(:HBox, term(:VBox, term(:InputField, term(:id, "ID"))))

      widget = nested.nested_find do |t|
        t.include?(term(:id, "ID"))
      end

      expect(widget.value).to eq :InputField
    end

    it "returns nil if it doesn't find any matching object" do
      nested = term(:HBox, term(:InputField, term(:id, "ID")))

      expect(nested.nested_find { |o| o == 5 }).to be_nil
    end
  end
end
