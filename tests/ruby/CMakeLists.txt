#
# CMakeLists.txt for yast2/ruby-bindings/tests/ruby
#

ENABLE_TESTING()

ADD_TEST(bindings_ruby_loading     ruby -C ${CMAKE_CURRENT_SOURCE_DIR} loading.rb)
