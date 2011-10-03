#
# CMakeLists.txt for yast2/ruby-bindings/tests/ycp
#

enable_testing()

add_test(from_ycp     ${CMAKE_CURRENT_SOURCE_DIR}/run_ycp_test.sh ${CMAKE_CURRENT_SOURCE_DIR}/ruby_from_ycp.ycp)
