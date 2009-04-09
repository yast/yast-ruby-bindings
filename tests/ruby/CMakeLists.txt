#
# CMakeLists.txt for yast2/ruby-bindings/tests/ruby
#

ENABLE_TESTING()

ADD_TEST(ruby_loading     ruby -C ${CMAKE_CURRENT_SOURCE_DIR} loading.rb)
ADD_TEST(ycp_iterators    ruby -C ${CMAKE_CURRENT_SOURCE_DIR} ycp_iterators.rb)
ADD_TEST(ycp_import       ruby -C ${CMAKE_CURRENT_SOURCE_DIR} ycp_import.rb)
ADD_TEST(module-arch      ruby -C ${CMAKE_CURRENT_SOURCE_DIR} module-arch.rb)
