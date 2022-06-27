#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/y2logger"

module Yast

  # testing exception class
  class TestException < StandardError; end

  describe Y2Logger do
    TEST_MESSAGE = "Testing".freeze

    before do
      @test_logger = Y2Logger.instance
    end

    it "logs debug messages via y2debug()" do
      expect(Yast).to receive(:y2debug).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.debug TEST_MESSAGE
    end

    it "logs info messages via y2milestone()" do
      expect(Yast).to receive(:y2milestone).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.info TEST_MESSAGE
    end

    it "logs warnings via y2warning()" do
      expect(Yast).to receive(:y2warning).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.warn TEST_MESSAGE
    end

    it "logs errors via y2error()" do
      expect(Yast).to receive(:y2error).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.error TEST_MESSAGE
    end

    it "logs fatal errors via y2error()" do
      expect(Yast).to receive(:y2error).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.fatal TEST_MESSAGE
    end

    it "handles a message passed via block" do
      expect(Yast).to receive(:y2milestone).with(Y2Logger::CALL_FRAME, TEST_MESSAGE)
      @test_logger.info { TEST_MESSAGE }
    end

    context "group logging" do
      it "raises ArgumentError exception when no block is not passed" do
        expect{ @test_logger.group(TEST_MESSAGE) }.to raise_error(ArgumentError)
      end

      it "evaluates the passed block" do
        expect{ |b| @test_logger.group(TEST_MESSAGE, &b) }.to yield_control
      end

      it "returns the block result" do
        value = "test"
        ret = @test_logger.group(TEST_MESSAGE) { value }

        # test the object identity, same object must be returned
        expect(ret).to equal(value)
      end

      it "logs special group begin and group end markers" do
        expect(Yast).to receive(:y2milestone).with(Y2Logger::CALL_FRAME, /::group::/)
        expect(Yast).to receive(:y2milestone).with(Y2Logger::CALL_FRAME, /::endgroup::/)
        @test_logger.group("") { }
      end

      it "logs the group description" do
        allow(Yast).to receive(:y2milestone)
        expect(Yast).to receive(:y2milestone) do |frame, message|
          expect(message).to end_with(TEST_MESSAGE)
        end

        @test_logger.group(TEST_MESSAGE) { }
      end

      it "logs the optional summary text" do
        summary = "optional summary text"
        # remember whether the summary was logged or not
        summary_included = false

        allow(Yast).to receive(:y2milestone)
        expect(Yast).to receive(:y2milestone) do |frame, message|
          summary_included = true if summary.end_with?(summary)
        end

        @test_logger.group(TEST_MESSAGE) { |g| g.summary = summary }
        expect(summary_included).to be true
      end

      it "logs error result when the block returns :abort" do
        expect(Yast).to receive(:y2error).with(Y2Logger::CALL_FRAME, /::endgroup::/)
        @test_logger.group(TEST_MESSAGE) { :abort }
      end

      it "logs error result when the failed status is set explicitly" do
        expect(Yast).to receive(:y2error).with(Y2Logger::CALL_FRAME, /::endgroup::/)
        @test_logger.group(TEST_MESSAGE) { |g| g.failed = true }
      end

      it "logs error result when reraises the exception from the block" do
        expect(Yast).to receive(:y2error).with(Y2Logger::CALL_FRAME, /::endgroup::/)
        expect{ @test_logger.group(TEST_MESSAGE) { raise TestException } }.to raise_error(TestException)
      end
    end

    it "does not crash when logging an invalid UTF-8 string" do
      # do not process this string otherwise you'll get an exception :-)
      invalid_utf8 = "invalid sequence: " + 0xE3.chr + 0x80.chr
      # just make sure it is really an invalid UTF-8 string
      invalid_utf8.force_encoding(Encoding::UTF_8)
      expect(invalid_utf8.valid_encoding?).to eq(false)
      expect { Yast.y2milestone(invalid_utf8) }.not_to raise_error
    end

    it "does not crash when logging ASCII string with invalid UTF-8" do
      # do not process this string otherwise you'll get an exception :-)
      invalid_ascii = "invalid sequence: " + 0xE3.chr + 0x80.chr
      invalid_ascii.force_encoding(Encoding::ASCII)
      expect { Yast.y2milestone(invalid_ascii) }.not_to raise_error
    end

    it "processes parameters using Builtins::sformat" do
      expected_log_msg = "test 1 2"
      expect(Yast).to receive(:y2_logger)
        .with(anything, "Ruby", anything, anything, anything, expected_log_msg)

      Yast.y2milestone("test %1 %2", 1, 2)
    end
  end

  describe Yast::Logger do
    it "module adds log() method for accessing the Logger" do
      class Test
        include Yast::Logger
      end
      expect(Test.log).to be_kind_of(::Logger)
      expect(Test.new.log).to be_kind_of(::Logger)
    end
  end
end
