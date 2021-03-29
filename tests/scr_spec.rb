#!/usr/bin/env rspec
# typed: false

require_relative "test_helper"

require "yast"

module Yast
  describe SCR do
    shared_examples "path_first_arg" do |method|
      describe ".#{method}" do
        # additional arguments for method
        let(:args) do
          arity = Yast::SCR.method(method).arity
          next [] if arity < 2
          Array.new(arity - 1, "test")
        end

        it "raises exception if first is not String or Yast::Path" do
          expect { Yast::SCR.public_send(method, 1, *args) }.to raise_error(ArgumentError)
        end

        it "passed path arguments with method name prepended to underlayer wrapper" do
          etc_path = Yast::Path.new(".etc")
          expect(Yast::SCR).to receive(:call_builtin_wrapper).with(method.to_s, etc_path, *args)
          Yast::SCR.public_send(method, etc_path, *args)
        end

        it "convert passed string as first argument to path" do
          etc_path = Yast::Path.new(".etc")
          expect(Yast::SCR).to receive(:call_builtin_wrapper).with(method.to_s, etc_path, *args)
          Yast::SCR.public_send(method, ".etc", *args)
        end
      end
    end

    include_examples "path_first_arg", :Read
    include_examples "path_first_arg", :Write
    include_examples "path_first_arg", :Execute
    include_examples "path_first_arg", :Dir
    include_examples "path_first_arg", :Error
    include_examples "path_first_arg", :RegisterAgent
    include_examples "path_first_arg", :UnregisterAgent
    include_examples "path_first_arg", :UnmountAgent
  end
end
