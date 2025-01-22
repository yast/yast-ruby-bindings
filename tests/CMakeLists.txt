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

# disable integration test as it is too fragile on non intel architectures
# ADD_TEST("integration"  ruby ${CMAKE_CURRENT_SOURCE_DIR}/integration/run.rb)
ADD_TEST("translations" rspec --format doc ${CMAKE_CURRENT_SOURCE_DIR}/integration/translations_spec.rb)

# disable also libyui tests as it is too fragile on non intel architectures and it is not ruby-bindings job to test it
# if wanted, it can live separately.
# file(GLOB libyui_specs "libyui/*_spec.rb")
# foreach(test ${libyui_specs})
#    ADD_TEST(${test}   rspec --format doc ${test})
# endforeach(test)
