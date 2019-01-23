#
# CMakeLists.txt for yast2/ruby-bindings/tests/ruby
#

ENABLE_TESTING()

FILE(GLOB Specs "*_spec.rb")

foreach(test ${Specs})
    ADD_TEST(${test}   rspec --format doc ${test})
endforeach(test)

ADD_TEST("integration"  ruby ${CMAKE_CURRENT_SOURCE_DIR}/integration/run.rb)
ADD_TEST("translations" rspec --format doc ${CMAKE_CURRENT_SOURCE_DIR}/integration/translations_spec.rb)
