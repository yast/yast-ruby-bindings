#
# CMakeLists.txt for yast2/ruby-bindings/tests/ruby
#

ENABLE_TESTING()

FILE(GLOB Specs "*_spec.rb")

foreach(test ${Specs})
    ADD_TEST(${test}   rspec --format doc ${test})
endforeach(test)
