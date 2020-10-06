# CMakeLists.txt for yast-ruby-bindings/tests

# use
#   make test
# or, for verbose output,
#   make test ARGS=-V
# ARGS is passed to ctest; see also
#   man ctest

ENABLE_TESTING()

FILE(GLOB Specs "*_spec.rb")

foreach(test ${Specs})
    ADD_TEST(${test}   rspec --format doc ${test})
endforeach(test)

ADD_TEST("integration"  ruby ${CMAKE_CURRENT_SOURCE_DIR}/integration/run.rb)
ADD_TEST("translations" rspec --format doc ${CMAKE_CURRENT_SOURCE_DIR}/integration/translations_spec.rb)

file(GLOB libyui_tests "libyui/*.test")
foreach(test ${libyui_tests})
    ADD_TEST(${test} ${test})
endforeach()
