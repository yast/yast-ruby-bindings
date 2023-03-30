require "memory_profiler"

MemoryProfiler.report {
  require "yast"

  Yast.import "Pkg"
  Yast.import "Bootloader"
  Yast.import "UI"
  Yast.import "Lan"
}.pretty_print
