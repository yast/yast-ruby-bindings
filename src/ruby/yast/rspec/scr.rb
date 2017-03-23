require "rspec"
require "yast"

module Yast
  module RSpec
    # RSpec extension to handle several agent operations.
    module SCR
      # Encapsulates SCR calls into a chroot.
      #
      # If a block if given, the SCR calls in the block are executed in the
      # chroot and the corresponding SCR instance is automatically closed when
      # the block ends (or if an exception is raised by the block).
      #
      # If a block is not given, the chroot must be explicitly closed calling
      # reset_root_path.
      #
      # Nesting of chroots is forbidden and the method will raise an exception
      # if is called without closing a previous chroot.
      #
      # @param directory [#to_s] directory to use as '/' for SCR calls
      #
      # @example Usage with a block
      #   change_scr_root("/home/chroot1") do
      #     # This reads the content of /home/chroot1/
      #     Yast::SCR.Read(path(".target.dir"), "/")
      #   end
      #
      # @example Usage without a block
      #   change_scr_root("/home/chroot1")
      #   # This reads the content of /home/chroot1/
      #   Yast::SCR.Read(path(".target.dir"), "/")
      #   reset_scr_root
      #
      # @example Usage within RSpec
      #   describe YaST::SCR do
      #     around { |example| change_scr_root("/home/chroot1", &example) }
      #
      #     describe "#Read" do
      #       it "works with the .proc.meminfo path"
      #         # This reads from /home/chroot1/proc/meminfo
      #         values = Yast::SCR.Read(path(".proc.meminfo"))
      #         expect(values).to include("key" => "value")
      #       end
      #     end
      #   end
      def change_scr_root(directory)
        if @scr_handle
          raise "There is already an open chrooted SCR instance, "\
            "a call to reset_scr_root was expected"
        end

        if !File.directory?(directory)
          raise "#{directory} is not a valid directory"
        end

        @scr_original_handle = Yast::WFM.SCRGetDefault
        check_version = false
        @scr_handle = Yast::WFM.SCROpen("chroot=#{directory}:scr", check_version)
        if @scr_handle < 0
          @scr_handle = nil
          @scr_original_handle = nil
          raise "Error creating the chrooted SCR instance"
        end
        Yast::WFM.SCRSetDefault(@scr_handle)

        return unless block_given?

        begin
          yield
        ensure
          reset_scr_root
        end
      end

      # Resets the SCR calls to prior behaviour, closing the SCR instance open
      # by the call to #change_scr_root.
      #
      # Raises an exception if #change_scr_root has not been called before or if
      # the corresponding instance has already been closed.
      #
      # @see #change_scr_root
      def reset_scr_root
        if @scr_handle.nil?
          raise "Unable to find a chrooted SCR instance to close"
        end

        default_handle = Yast::WFM.SCRGetDefault
        if default_handle != @scr_handle
          raise "Error closing the chrooted SCR instance, "\
            "it's not the current default one"
        end

        Yast::WFM.SCRClose(default_handle)
        Yast::WFM.SCRSetDefault(@scr_original_handle)
      ensure
        @scr_handle = nil
        @scr_original_handle = nil
      end
    end
  end
end
