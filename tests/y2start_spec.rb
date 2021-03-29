#!/usr/bin/env rspec
# typed: false
# encoding: utf-8

require_relative "test_helper"

describe "y2start" do
  let(:script_path) do
    cmd = "ruby"
    cmd << " -I #{BINARY_PATH}"
    cmd << " -I #{RUBY_INC_PATH}"
    cmd << " --"
    cmd << " #{ROOT_DIR}/src/y2start/y2start"
  end

  it "prints helps and exit 0 if run with --help" do
    expect(`#{script_path} --help 2>&1`).to match(/Usage/)
    expect($?.exitstatus).to eq 0
  end

  it "prints help and exit 1 if invalid argument passed" do
    expect(`#{script_path} --invalid 2>&1`).to match(/Usage/)
    expect($?.exitstatus).to eq 1
  end

  it "prints that client not found and exit 1 if client not found" do
    expect(`#{script_path} invalid UI 2>&1`).to match(/No such client/)
    expect($?.exitstatus).to eq 1
  end
end
