require "yast/rake"

Yast::Tasks.submit_to :sle15sp6
require "rbconfig"

Yast::Tasks.configuration do |conf|
  # lets ignore license check for now
  conf.skip_license_check << /.*/

  # support installation via "yupdate" script in the inst-sys,
  # we can only install the Ruby scripts because the C compiler and the development
  # files are missing in the inst-sys, but this might be enough in some cases...
  # this replicates the tasks from src/CMakeLists.txt
  conf.install_locations["src/y2start/y2start"] = File.join(Packaging::Configuration::YAST_LIB_DIR, "bin")
  vendor_dir = File.join(Packaging::Configuration::DESTDIR, RbConfig::CONFIG["vendorlibdir"])
  conf.install_locations["src/ruby/yast.rb"] = vendor_dir
  conf.install_locations["src/ruby/yast"] = vendor_dir
end
