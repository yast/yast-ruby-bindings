#
# CMakeLists.txt for yast2/ruby-bindings/tests
#

enable_testing()

# Ruby -> YaST tests
add_subdirectory(ruby)

# YCP -> Ruby tests
add_subdirectory(ycp)
