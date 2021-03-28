#!/usr/bin/env rspec
# typed: false
# encoding: utf-8

# FIXME: this file was autoconverted from test/unit syntax without
# adjusting it to good RSpec style (http://betterspecs.org/).
# Please improve it whenever adding examples.

require_relative "test_helper"

require "yast/builtins"
require "yast/path"
require "yast/term"
require "yast/break"

require "date"

describe Yast::Builtins do
  describe ".add" do
    ADD_TEST_DATA = [
      [nil, 5, nil],
      [[1, 2], 3, [1, 2, 3]],
      [{ a: 1, b: 2 }, [:c, 3], { a: 1, b: 2, c: 3 }],
      [Yast::Path.new(".etc"),
       Yast::Path.new(".sysconfig"),
       Yast::Path.new(".etc.sysconfig")],
      [Yast::Path.new(".etc"), "sysconfig", Yast::Path.new(".etc.sysconfig")],
      [Yast::Term.new(:a, :b), :c, Yast::Term.new(:a, :b, :c)]
    ].freeze

    it "works as expected" do
      ADD_TEST_DATA.each do |object, element, result|
        duplicate_object = object.nil? ? nil : object.dup
        res = Yast::Builtins.add(duplicate_object, *element)
        expect(res).to eq(result)
        expect(duplicate_object).to eq(object)
      end
    end

    it "uses deep copy" do
      a = [["a"]]
      b = Yast::Builtins.add(a, "b")
      b[0][0] = "c"
      expect(a).to eq([["a"]])
    end
  end

  describe ".size" do
    it "works as expected" do
      expect(Yast::Builtins.size(nil)).to eq(nil)
      expect(Yast::Builtins.size([])).to eq(0)
      expect(Yast::Builtins.size({})).to eq(0)
      expect(Yast::Builtins.size("")).to eq(0)

      expect(Yast::Builtins.size(Yast::Term.new(:HBox))).to eq(0)
      expect(Yast::Builtins.size(Yast::Term.new(:HBox, "test"))).to eq(1)
      expect(Yast::Builtins.size(Yast::Term.new(:HBox, "test", "test"))).to eq(2)
      expect(Yast::Builtins.size(Yast::Term.new(:HBox, Yast::Term.new(:VBox, "test", "test")))).to eq(1)
    end
  end

  describe ".time" do
    it "works as expected" do
      expect(Yast::Builtins.time).to be > 0
    end
  end

  describe ".find" do
    context "looking into a string" do
      it "works as expected" do
        expect(Yast::Builtins.find(nil, nil)).to eq(nil)
        expect(Yast::Builtins.find("", nil)).to eq(nil)

        expect(Yast::Builtins.find("", "")).to eq(0)
        expect(Yast::Builtins.find("1234", "3")).to eq(2)
        expect(Yast::Builtins.find("1234", "3")).to eq(2)
        expect(Yast::Builtins.find("1234", "9")).to eq(-1)
      end

      it "raises TypeError when used incompatibly with YCP" do
        # before introducing sorbet it would raise a confusing error:
        # `index': type mismatch: NilClass given (TypeError)
        # Now the type error is nicer
        expect { Yast::Builtins.find("foo") { "o" } }.to raise_error(TypeError)
      end
    end

    context "looking into a list" do
      it "works as expected" do
        test_list = [2, 3, 4]
        expect(Yast::Builtins.find(nil) { |_i| next true }).to eq(nil)
        expect(Yast::Builtins.find(test_list) { |_i| next true }).to eq(2)
        expect(Yast::Builtins.find(test_list) { |i| next i > 2 }).to eq(3)
      end

      it "raises TypeError when used incompatibly with YCP" do
        # before introducing sorbet it would confusingly return an Enumerator
        expect { Yast::Builtins.find([1, 2], 3) }.to raise_error(TypeError)
      end
    end

    context "looking into another type" do
      it "raises TypeError" do
        # before sorbet:
        # `find': Invalid object for find() builtin (RuntimeError)
        expect { Yast::Builtins.find({one: 1}, 2) }.to raise_error(TypeError)
      end
    end
  end

  describe ".contains" do
    it "works as expected" do
      expect(Yast::Builtins.contains(nil, nil)).to eq(nil)
      expect(Yast::Builtins.contains([], nil)).to eq(nil)
      expect(Yast::Builtins.contains(nil, "")).to eq(nil)

      expect(Yast::Builtins.contains([], "")).to eq(false)
      expect(Yast::Builtins.contains(["A", "B", "C"], "")).to eq(false)
      expect(Yast::Builtins.contains(["A", "B", "C"], "X")).to eq(false)
      expect(Yast::Builtins.contains(["A", "B", "C"], "B")).to eq(true)
    end
  end

  describe ".merge" do
    it "works as expected" do
      expect(Yast::Builtins.merge(nil, nil)).to eq(nil)
      expect(Yast::Builtins.merge([], nil)).to eq(nil)
      expect(Yast::Builtins.merge(nil, [])).to eq(nil)

      expect(Yast::Builtins.merge([], [])).to eq([])
      expect(Yast::Builtins.merge(["A"], [])).to eq(["A"])
      expect(Yast::Builtins.merge(["A"], ["B"])).to eq(["A", "B"])
      expect(Yast::Builtins.merge(["A"], [1])).to eq(["A", 1])
    end
  end

  describe ".sort" do
    it "works as expected" do
      expect(Yast::Builtins.sort(nil)).to eq(nil)

      expect(Yast::Builtins.sort([])).to eq([])
      expect(Yast::Builtins.sort(["A"])).to eq(["A"])
      expect(Yast::Builtins.sort(["Z", "A"])).to eq(["A", "Z"])
      expect(Yast::Builtins.sort([3, 2, 1])).to eq([1, 2, 3])

      expect(Yast::Builtins.sort(["10", 1, 2, 10, 20, "15", 200, 5])).to eq([1, 2, 5, 10, 20, 200, "10", "15"])

      expect(Yast::Builtins.sort([10, 1, 20]) { |x, y| x > y }).to eq([20, 10, 1])
    end
  end

  describe ".change" do
    it "works as expected" do
      a = [1, 2]
      expect(Yast::Builtins.change(a, 3)).to eq([1, 2, 3])
      expect(a).to eq([1, 2])

      h = { a: 1, b: 2 }
      res = Yast::Builtins.change(h, :c, 3)
      expect(res).to eq(a: 1, b: 2, c: 3)
      expect(h).to eq(a: 1, b: 2)
    end
  end

  describe ".isempty" do
    it "works as expected" do
      expect(Yast::Builtins.isempty(nil)).to eq(nil)
      expect(Yast::Builtins.isempty([])).to eq(true)
      expect(Yast::Builtins.isempty({})).to eq(true)
      expect(Yast::Builtins.isempty("")).to eq(true)
      expect(Yast::Builtins.isempty([1])).to eq(false)
      expect(Yast::Builtins.isempty("a" => "b")).to eq(false)
      expect(Yast::Builtins.isempty("foo")).to eq(false)
    end
  end

  describe ".srandom" do
    it "works as expected" do
      expect(Yast::Builtins.srandom).to be > 0
      expect(Yast::Builtins.srandom(10)).to eq(nil)
    end
  end

  describe ".search" do
    it "works as expected" do
      expect(Yast::Builtins.search(nil, nil)).to eq(nil)
      expect(Yast::Builtins.search("", nil)).to eq(nil)

      expect(Yast::Builtins.search("", "")).to eq(0)
      expect(Yast::Builtins.search("1234", "3")).to eq(2)
      expect(Yast::Builtins.search("1234", "3")).to eq(2)
      expect(Yast::Builtins.search("1234", "9")).to eq(nil)
    end
  end

  describe ".haskey" do
    it "works as expected" do
      expect(Yast::Builtins.haskey(nil, nil)).to eq(nil)
      expect(Yast::Builtins.haskey({}, nil)).to eq(nil)
      expect(Yast::Builtins.haskey(nil, "")).to eq(nil)

      expect(Yast::Builtins.haskey({}, "")).to eq(false)
      expect(Yast::Builtins.haskey({ "a" => 1 }, "a")).to eq(true)
      expect(Yast::Builtins.haskey({ "a" => 1 }, "b")).to eq(false)
    end
  end

  describe ".lookup" do
    it "works as expected" do
      expect(Yast::Builtins.lookup({}, nil, nil)).to eq(nil)
      expect(Yast::Builtins.lookup({}, "", nil)).to eq(nil)
      expect(Yast::Builtins.lookup({ "a" => 1 }, "a", 2)).to eq(1)
      expect(Yast::Builtins.lookup({ "a" => 1 }, "b", 2)).to eq(2)
    end
  end

  describe ".filter" do
    context "operating on a list" do
      it "works as expected" do
        expect(Yast::Builtins.filter(nil)).to eq(nil)
        expect(Yast::Builtins.filter([2, 3, 4]) { |_i| next true }).to eq([2, 3, 4])
        expect(Yast::Builtins.filter([2, 3, 4]) { |i| next i > 3 }).to eq([4])
        expect(Yast::Builtins.filter([2, 3, 4]) { |i| next i > 4 }).to eq([])
      end
    end

    context "operating on a map" do
      it "works as expected" do
        test_hash = { 2 => 3, 3 => 4 }
        expect(Yast::Builtins.filter(test_hash) { |_i, _j| next true }).to eq(Hash[2 => 3, 3 => 4])
        expect(Yast::Builtins.filter(test_hash) { |i, _j| next i > 2 }).to eq(Hash[3 => 4])
        expect(Yast::Builtins.filter(test_hash) { |i, _j| next i > 4 }).to eq({})
      end
    end
  end

  describe ".each" do
    context "iterating through a list" do
      it "works as expected" do
        expect(Yast::Builtins.foreach(nil) { |_i| next 5 }).to eq(nil)
        list = [2, 3, 4]
        cycle_detect = 0
        res = Yast::Builtins.foreach(list) do |l|
          cycle_detect += 1
          next l
        end
        expect(res).to eq(4)
        expect(cycle_detect).to eq(3)
        cycle_detect = 0
        res = Yast::Builtins.foreach(list) do |l|
          cycle_detect += 1
          raise Yast::Break if l == 3
        end
        expect(res).to eq(nil)
        expect(cycle_detect).to eq(2)
        cycle_detect = 0
        res = Yast::Builtins.foreach(list) do |l|
          cycle_detect += 1
          next l + 3
        end
        expect(res).to eq(7)
        expect(cycle_detect).to eq(3)
      end
    end

    context "iterating through a map" do
      it "works as expected" do
        map = { 2 => 3, 3 => 4 }
        cycle_detect = 0
        res = Yast::Builtins.foreach(map) do |k, _v|
          cycle_detect += 1
          next k
        end
        expect(res).to eq(3)
        expect(cycle_detect).to eq(2)
        cycle_detect = 0
        res = Yast::Builtins.foreach(map) do |k, _v|
          cycle_detect += 1
          raise Yast::Break if k == 2
        end
        expect(res).to eq(nil)
        expect(cycle_detect).to eq(1)
        cycle_detect = 0
        res = Yast::Builtins.foreach(map) do |_k, v|
          cycle_detect += 1
          next v + 3
        end
        expect(res).to eq(7)
        expect(cycle_detect).to eq(2)
      end
    end
  end

  describe ".maplist" do
    it "works as expected" do
      expect(Yast::Builtins.maplist(nil) { |_i| next 5 }).to eq(nil)

      list = [2, 3, 4]
      res = Yast::Builtins.maplist(list) do |l|
        next l
      end
      expect(res).to eq([2, 3, 4])

      res = Yast::Builtins.maplist(list) do |l|
        raise Yast::Break if l == 3
        l
      end
      expect(res).to eq([2])

      res = Yast::Builtins.maplist(list) do |l|
        next if l == 3
        next l + 3
      end
      expect(res).to eq([5, nil, 7])
    end
  end

  describe ".remove" do
    context "operating on a list" do
      it "works as expected" do
        list = [0, 1, 2, 3]

        expect(Yast::Builtins.remove(nil, 2)).to eq(nil)

        expect(Yast::Builtins.remove(list, 2)).to eq([0, 1, 3])

        expect(Yast::Builtins.remove(list, 5)).to eq([0, 1, 2, 3])
        expect(Yast::Builtins.remove(list, -1)).to eq([0, 1, 2, 3])
      end
    end

    context "operating on a map" do
      it "works as expected" do
        list = { 0 => 1, 2 => 3 }

        expect(Yast::Builtins.remove(nil, 2)).to eq(nil)

        expect(Yast::Builtins.remove(list, 2)).to eq(Hash[0 => 1])
        expect(list).to eq(Hash[0 => 1, 2 => 3])

        expect(Yast::Builtins.remove(list, 5)).to eq(Hash[0 => 1, 2 => 3])
      end
    end

    context "operating on a term" do
      it "works as expected" do
        term = Yast::Term.new :t, :a, :b

        expect(Yast::Builtins.remove(term, 2)).to eq(Yast::Term.new(:t, :a))
        expect(term).to eq(Yast::Term.new(:t, :a, :b))

        expect(Yast::Builtins.remove(term, 5)).to eq(Yast::Term.new(:t, :a, :b))
        expect(Yast::Builtins.remove(term, -1)).to eq(Yast::Term.new(:t, :a, :b))
      end
    end
  end

  describe ".select" do
    it "works as expected" do
      list = [0, 1, 2]
      expect(Yast::Builtins.select(list, 1, -1)).to eq 1
    end
  end

  describe ".union" do
    UNION_TESTDATA = [
      [nil, nil, nil],
      [nil, [3, 4], nil],
      [[1, 2], nil, nil],
      [[1, 2], [3, 4], [1, 2, 3, 4]],
      [[1, 2, 3, 1], [3, 4], [1, 2, 3, 4]],
      [[1, 2, nil], [3, nil, 4], [1, 2, nil, 3, 4]],
      [{ 1 => 2, 2 => 3 }, { 2 => 10, 4 => 5 }, { 1 => 2, 2 => 10, 4 => 5 }]
    ].freeze

    it "works as expected" do
      UNION_TESTDATA.each do |first, second, result|
        expect(Yast::Builtins.union(first, second)).to eq(result)
      end
    end
  end

  describe ".flatten" do
    FLATTEN_TESTDATA = [
      [nil, nil],
      [[nil], nil],
      [[[1, 2], nil], nil],
      [[[1, 2], [3, nil]], [1, 2, 3, nil]],
      [[[0, 1], [2, [3, 4]]], [0, 1, 2, [3, 4]]],
      [[[0, 1], [2, 3], [3, 4]], [0, 1, 2, 3, 3, 4]]
    ].freeze

    it "works as expected" do
      FLATTEN_TESTDATA.each do |value, result|
        expect(Yast::Builtins.flatten(value)).to eq(result)
      end
    end
  end

  describe ".listmap" do
    it "works as expected" do
      expect(Yast::Builtins.listmap(nil) { |i| next { i => i } }).to eq(nil)

      expect(Yast::Builtins.listmap([1, 2]) { |i| next { i => i } }).to eq(Hash[1 => 1, 2 => 2])
    end
  end

  describe ".prepend" do
    PREPEND_TESTDATA = [
      [nil, 5, nil],
      [[0, 1], 5, [5, 0, 1]],
      [[1, 2], nil, [nil, 1, 2]]
    ].freeze

    it "works as expected" do
      PREPEND_TESTDATA.each do |list, element, result|
        list_prev = list.nil? ? nil : list.dup
        expect(Yast::Builtins.prepend(list, element)).to eq(result)
        # check that list is not modified
        expect(list).to eq(list_prev)
      end
    end
  end

  describe ".sublist" do
    SUBLIST_TEST_DATA_WITH_LEN = [
      [nil, 1, 1, nil],
      [[0, 1], nil, nil, nil],
      [[0, 1], 2, 1, nil],
      [[0, 1], 1, 2, nil],
      [[0, 1], 1, 1, [1]],
      [[0, 1], 1, 0, []]
    ].freeze

    SUBLIST_TEST_DATA_WITHOUT_LEN = [
      [nil, 1, nil],
      [[0, 1], nil, nil],
      [[0, 1], 2, nil],
      [[0, 1], 0, [0, 1]],
      [[0, 1], 1, [1]]
    ].freeze

    it "works as expected with len" do
      SUBLIST_TEST_DATA_WITH_LEN.each do |list, offset, length, result|
        list_prev = list.nil? ? nil : list.dup
        expect(Yast::Builtins.sublist(list, offset, length)).to eq(result)
        # check that list is not modified
        expect(list).to eq(list_prev)
      end
    end

    it "works as expected withoit len" do
      SUBLIST_TEST_DATA_WITHOUT_LEN.each do |list, offset, result|
        list_prev = list.nil? ? nil : list.dup
        expect(Yast::Builtins.sublist(list, offset)).to eq(result)
        # check that list is not modified
        expect(list).to eq(list_prev)
      end
    end
  end

  describe ".mapmap" do
    it "works as expected" do
      expect(Yast::Builtins.listmap(nil) { |k, v| next { v => k } }).to eq(nil)

      # bnc#888585: Incorrect input class raises TypeError
      # Only Hash/nil is allowed
      expect { Yast::Builtins.mapmap(false) { |k, v| { v => k } } }.to raise_error(TypeError)
      expect { Yast::Builtins.mapmap(["Array"]) { |k, v| { v => k } } }.to raise_error(TypeError)
      expect { Yast::Builtins.mapmap("String") { |k, v| { v => k } } }.to raise_error(TypeError)
      expect { Yast::Builtins.mapmap(32) { |k, v| { v => k } } }.to raise_error(TypeError)

      expect(Yast::Builtins.mapmap(nil) { |k, v| { v => k } }).to eq(nil)

      expect(Yast::Builtins.mapmap(2 => 1, 4 => 3) { |k, v| next { v => k } }).to eq(Hash[1 => 2, 3 => 4])

      res = Yast::Builtins.mapmap(2 => 1, 4 => 3) do |k, v|
        raise Yast::Break if k == 4
        next { v => k }
      end

      expect(res).to eq Hash[1 => 2]
    end
  end

  describe ".random" do
    it "works as expected" do
      expect(Yast::Builtins.random(nil)).to be_nil

      # there is quite nice chance with this repetition to test even border or range
      100.times do
        expect(0..9).to cover Yast::Builtins.random(10)
      end
    end
  end

  describe ".sformat" do
    it "works as expected" do
      expect(Yast::Builtins.sformat(nil)).to eq(nil)
      expect(Yast::Builtins.sformat("test")).to eq("test")
      expect(Yast::Builtins.sformat("test %1")).to eq("test %1")
      expect(Yast::Builtins.sformat("test%a", "lest")).to eq("test")
      expect(Yast::Builtins.sformat("test%%", "lest")).to eq("test%")
      expect(Yast::Builtins.sformat("test%3%2%1", 1, 2, 3)).to eq("test321")

      expect(Yast::Builtins.sformat("test %1", "lest")).to eq("test lest")

      expect(Yast::Builtins.sformat("test %1", :lest)).to eq("test `lest")
    end
  end

  describe ".findfirstof" do
    FINDFIRSTOF_TESTDATA = [
      [nil, "ab", nil],
      ["ab", nil, nil],
      ["aaaaa", "z", nil],
      ["abcdefg", "cxdv", 2],
      ["\s\t\n", "\s", 0],
      ["\s\t\n", "\n", 2]
    ].freeze

    it "works as expected" do
      FINDFIRSTOF_TESTDATA.each do |string, chars, result|
        expect(Yast::Builtins.findfirstof(string, chars)).to eq(result)
      end
    end
  end

  describe ".findfirstnotof" do
    FINDFIRSTNOTOF_TESTDATA = [
      [nil, "ab", nil],
      ["ab", nil, nil],
      ["aaaaa", "z", 0],
      ["abcdefg", "cxdv", 0],
      ["\s\t\n", "\s", 1],
      ["\n\n\t", "\n", 2]
    ].freeze

    it "works as expected" do
      FINDFIRSTNOTOF_TESTDATA.each do |string, chars, result|
        expect(Yast::Builtins.findfirstnotof(string, chars)).to eq(result)
      end
    end
  end

  describe ".findlastof" do
    FINDLASTOF_TESTDATA = [
      [nil, "ab", nil],
      ["ab", nil, nil],
      ["aaaaa", "z", nil],
      ["abcdefg", "cxdv", 3],
      ["\s\t\n", "\s", 0],
      ["\s\t\n", "\n", 2]
    ].freeze

    it "works as expected" do
      FINDLASTOF_TESTDATA.each do |string, chars, result|
        expect(Yast::Builtins.findlastof(string, chars)).to eq(result)
      end
    end
  end

  describe ".findlastnotof" do
    FINDLASTNOTOF_TESTDATA = [
      [nil, "ab", nil],
      ["ab", nil, nil],
      ["aaaaa", "z", 4],
      ["abcdefg", "cxdv", 6],
      ["\s\t\s", "\s", 1],
      ["\t\n\n", "\n", 0]
    ].freeze

    it "works as expected" do
      FINDLASTNOTOF_TESTDATA.each do |string, chars, result|
        expect(Yast::Builtins.findlastnotof(string, chars)).to eq(result)
      end
    end
  end

  describe ".crypt" do
    it "works as expected" do
      suffixes = ["", "md5", "blowfish", "sha256", "sha512"]

      suffixes.each do |suffix|
        res = Yast::Builtins.send(:"crypt#{suffix}", "test")
        # crypt result is salted and cannot be reproduced
        # just test if it runs and returns something meaningfull
        expect(res).to be_a String
        expect(res.size).to be > 10
      end
    end
  end

  describe ".lsort" do
    it "works as expected" do
      expect(Yast::Builtins.lsort(["c", "b", "a"])).to eq(["a", "b", "c"])
      expect(Yast::Builtins.lsort([3, 2, 1])).to eq([1, 2, 3])
      expect(Yast::Builtins.lsort([3, "a", 2, "b", 1])).to eq([1, 2, 3, "a", "b"])
      expect(Yast::Builtins.lsort(["a", 50, "z", true])).to eq([true, 50, "a", "z"])
    end
  end

  describe ".eval" do
    EVAL_TEST_DATA = [
      [nil, nil],
      [5, 5],
      [proc { "15" }, "15"]
    ].freeze

    it "works as expected" do
      EVAL_TEST_DATA.each do |input, result|
        expect(Yast::Builtins.eval(input)).to eq(result)
      end
    end
  end

  describe ".deletechars" do
    DELETECHARS_TEST_DATA = [
      [nil, nil, nil],
      ["test", nil, nil],
      [nil, "a", nil],
      ["a", "abcdefgh", ""],
      ["abc", "cde", "ab"],
      ["abc", "a-c", "b"],
      ["abc", "^ab", "c"]
    ].freeze

    it "works as expected" do
      DELETECHARS_TEST_DATA.each do |input1, input2, result|
        expect(Yast::Builtins.deletechars(input1, input2)).to eq(result)
      end
    end
  end

  describe ".filterchars" do
    FILTERCHARS_TEST_DATA = [
      [nil, nil, nil],
      ["test", nil, nil],
      [nil, "a", nil],
      ["a", "abcdefgh", "a"],
      ["abc", "cde", "c"],
      ["abc", "a-c", "ac"],
      ["abc", "^ab", "ab"]
    ].freeze

    it "works as expected" do
      FILTERCHARS_TEST_DATA.each do |input1, input2, result|
        expect(Yast::Builtins.filterchars(input1, input2)).to eq(result)
      end
    end
  end

  describe ".deep_copy" do
    it "works as expected" do
      a = [[1, 2], [2, 3]]
      b = Yast.deep_copy a
      b[0][0] = 10
      expect(a[0][0]).to eq(1)
      expect(b[0][0]).to eq(10)
    end
  end

  describe ".strftime" do
    before(:all) do
      @original_lang = ENV["LANG"]
      ENV["LANG"] = "C"
    end

    after(:all) do
      ENV["LANG"] = @original_lang
    end

    let(:time) { Time.new(1980, 2, 29, 12, 13, 14, "+00:00") }
    let(:datetime) { DateTime.parse("2015-06-26") }
    let(:date) { time.to_date }
    let(:format) { "%B - %d - %H:%M:%S" }

    it "raises an exception if the result is too long" do
      expect { Yast::Builtins.strftime(time, "%B" + " " * 300) }.to raise_error(RuntimeError)
    end

    it "raises an exception for Date objects (incomplete time)" do
      expect { Yast::Builtins.strftime(date, format) }.to raise_error(ArgumentError)
    end

    it "returns the formatted time for Time objects" do
      expect(Yast::Builtins.strftime(time, format)).to eq "February - 29 - 12:13:14"
    end

    it "returns the formatted time for DateTime objects" do
      expect(Yast::Builtins.strftime(datetime, format)).to eq "June - 26 - 00:00:00"
    end

    # NOTE: this needs the cs_CZ locale to be available in the system
    context "in a system set to Czech" do
      around do |example|
        old_lang = ENV["LANG"]
        old_lc = ENV["LC_ALL"]
        ENV["LANG"] = "cs_CZ.utf-8"
        ENV["LC_ALL"] = "cs_CZ.utf-8"
        example.run
        ENV["LANG"] = old_lang
        ENV["LC_ALL"] = old_lc
      end

      # glibc changed the translations (see bsc #1107953) so just match both
      it "returns the localized formatted time" do
        expect(Yast::Builtins.strftime(time, format)).to match "(\u00FAnor|\u00FAnora) - 29 - 12:13:14"
      end
    end
  end
end
