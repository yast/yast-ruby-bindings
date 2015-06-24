#!/usr/bin/env rspec

require_relative "test_helper"

require "yast/rspec"

describe Yast::RSpec::SCR do
  let(:chroot) { File.join(File.dirname(__FILE__), "chroot") }

  class DummyError < Exception; end

  def root_content
    Yast::SCR.Read(path(".target.dir"), "/")
  end

  describe "#change_scr_root" do
    describe "file check" do
      it "raises an exception if the directory does not exist" do
        expect { change_scr_root("not/found/file") }
          .to raise_exception(RuntimeError, /not a valid directory/)
      end

      it "raises an exception if called on a regular file" do
        expect { change_scr_root(File.join(chroot, "just_a_file")) }
          .to raise_exception(RuntimeError, /not a valid directory/)
      end
    end

    describe "block syntax" do
      it "changes the root path inside the block" do
        expect(root_content).not_to eq(["just_a_file"])
        change_scr_root(chroot) do
          expect(root_content).to eq(["just_a_file"])
        end
      end

      it "restores the original path after running the block" do
        change_scr_root(chroot) do
          # Do something in the chroot
        end
        expect(root_content).not_to eq(["just_a_file"])
      end

      it "restores the original path after a exception" do
        expect { change_scr_root(chroot) { raise DummyError } }
          .to raise_exception(DummyError)
        expect(root_content).not_to eq(["just_a_file"])
      end

      it "raises an exception for nested calls" do
        change_scr_root(chroot) do
          expect { change_scr_root(chroot) }
            .to raise_exception(RuntimeError, /reset_scr_root was expected/)
        end
        expect(root_content).not_to eq(["just_a_file"])
      end
    end

    describe "usage with an around hook" do
      around { |example| change_scr_root(chroot, &example) }

      it "changes the root path within the example" do
        expect(root_content).to eq(["just_a_file"])
      end

      it "raises an exception for nested calls" do
        expect { change_scr_root(chroot) }
          .to raise_exception(RuntimeError, /reset_scr_root was expected/)
      end
    end

    describe "non-block syntax" do
      after do
        reset_scr_root
      end

      it "changes the root path" do
        expect(root_content).not_to eq(["just_a_file"])
        change_scr_root(chroot)
        expect(root_content).to eq(["just_a_file"])
      end

      it "raises an exception for consecutive calls" do
        change_scr_root(chroot)
        expect { change_scr_root(chroot) }
          .to raise_exception(RuntimeError, /reset_scr_root was expected/)
      end
    end
  end

  describe "#reset_scr_root" do
    it "restores the original path" do
      change_scr_root(chroot)
      reset_scr_root
      expect(root_content).not_to eq(["just_a_file"])
    end

    it "raises an exception if #change_scr_root was not called before" do
      expect { reset_scr_root }
        .to raise_exception(RuntimeError, /Unable to find a chrooted SCR/)
    end

    it "raises an exception if default SCR was modified" do
      original_handle = Yast::WFM.SCRGetDefault
      change_scr_root(chroot)

      # Manually close the chroot
      Yast::WFM.SCRClose(Yast::WFM.SCRGetDefault)
      Yast::WFM.SCRSetDefault(original_handle)

      expect { reset_scr_root }
        .to raise_exception(RuntimeError, /not the current default/)
    end
  end
end
