#!/usr/bin/env rspec
# encoding: utf-8

require_relative "test_helper"

require "yast/core_ext"

describe "core_ext" do
  it "requires the String extensions" do
    expect("string").to respond_to(:remove_ansi_sequences)
  end
end
