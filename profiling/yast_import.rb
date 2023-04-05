require "memory_profiler"

usage = <<CMD
cd build # cmake ..; make
# use the built version
ruby -r ../tests/test_helper.rb ../profiling/yast_import.rb  # | head -n2
# use the system version
ruby                            ../profiling/yast_import.rb  # | head -n2
CMD

MemoryProfiler.report {
  require "yast"

  Yast.import "Pkg"
  Yast.import "Bootloader"
  Yast.import "UI"
  Yast.import "Lan"
}.pretty_print
