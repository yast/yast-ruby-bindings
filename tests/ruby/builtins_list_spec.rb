#!/usr/bin/env rspec
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"

describe Yast::Builtins::List do
  describe ".reduce" do
    context "one param" do
      it "works as expected" do
      list = [0,1,2,3,2,1,-5]
      res = Yast::Builtins::List.reduce(list) do |x,y|
        next x>y ? x : y
      end

      expect(res).to eq(3)

      res = Yast::Builtins::List.reduce(list) do |x,y|
        next x + y
      end
      expect(res).to eq(4)

      expect(Yast::Builtins::List.reduce([]) { |x,y| next x }).to eq(nil)
      expect(Yast::Builtins::List.reduce(nil) { |x,y| next x }).to eq(nil)
      end
    end

    context "two params" do
      it "works as expected" do
      list = [0,1,2,3,2,1,-5]
      res = Yast::Builtins::List.reduce(15,list) do |x,y|
        next x>y ? x : y
      end

      expect(res).to eq(15)

      res = Yast::Builtins::List.reduce(15,list) do |x,y|
        next x + y
      end

      expect(res).to eq(19)

      expect(Yast::Builtins::List.reduce(5,[]) { |x,y| next x }).to eq(5)
      expect(Yast::Builtins::List.reduce(nil,nil) { |x,y| next x }).to eq(nil)
      end
    end
  end

  describe ".swap" do
    SWAP_TESTDATA = [
      [nil,nil,nil,nil],
      [[0],nil,0,nil],
      [[0],0,nil,nil],
      [[0],0,nil,nil],
      [[5,6],-1,1,[5,6]],
      [[5,6],0,2,[5,6]],
      [[0,1,2,3],0,3,[3,2,1,0]],
      [[0,1,2,3],0,2,[2,1,0,3]],
      [[0,1,2,3],1,3,[0,3,2,1]],
      [[0,1,2,3],2,2,[0,1,2,3]],
    ]

    it "works as expected" do
      SWAP_TESTDATA.each do |list,offset1,offset2,result|
        list_prev = list.nil? ? nil : list.dup
        expect(Yast::Builtins::List.swap(list, offset1, offset2)).to eq(result)
        #check that list is not modified
        expect(list).to eq(list_prev)
      end
    end
  end
end
