#
# CMakeLists.txt for yast2/ruby-bindings
#

cmake_minimum_required(VERSION 2.4)
if(COMMAND cmake_policy)
  # let cmake escape preprocessor definitions
  cmake_policy(SET CMP0005 NEW)
endif()

project(yast2-ruby-bindings)
set(PACKAGE "yast2-ruby-bindings")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O3 -Wall -Woverloaded-virtual")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   -g -O3 -Wall")

#
# Where is YaST ?
#

find_package(Yast REQUIRED)
if(NOT YAST_LIBRARY)
  message(FATAL_ERROR "Please install yast2-core-devel.")
endif()

if(NOT YAST_PLUGIN_UI_LIBRARY)
  message(FATAL_ERROR "YAST_PLUGIN_UI_LIBRARY not set, please install yast2-ycp-ui-bindings-devel.")
endif()

#
# Where is Ruby ?
#

find_package(Ruby REQUIRED)
if(NOT RUBY_EXECUTABLE)
  message(FATAL_ERROR "Ruby not found.")
endif()

#
# -> src/
#

add_subdirectory(src)

#
# -> tests/
#
include(CTest)
enable_testing()

add_subdirectory(tests)

#
# packaging
#
set(RPMNAME "yast2-ruby-bindings")

generate_packaging(${RPMNAME} ${VERSION})
