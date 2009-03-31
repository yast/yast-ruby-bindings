#
# CMakeLists.txt for yast2/ruby-bindings
#

cmake_minimum_required(VERSION 2.4)
if(COMMAND cmake_policy)
  # escape preprocessor, see -DVERSION below
  cmake_policy(SET CMP0005 OLD)
endif(COMMAND cmake_policy)
    

PROJECT(yast2-ruby-bindings)
SET(PACKAGE "yast2-ruby-bindings")
SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O3 -Wall -Woverloaded-virtual" )
SET( CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   -g -O3 -Wall" )

#
# Where is SWIG ?
#

FIND_PACKAGE(SWIG)
IF ( NOT SWIG_FOUND )

FIND_PROGRAM(SWIG_EXECUTABLE
  NAMES swig-1.3 swig
  PATHS ${SWIG_DIR} ${SWIG_DIR}/.. ${SWIG_DIR}/../../bin /usr/bin /usr/local/bin ${CMAKE_INSTALL_PREFIX}/bin
)
ENDIF ( NOT SWIG_FOUND )

IF ( NOT SWIG_EXECUTABLE )
  MESSAGE( FATAL_ERROR "SWIG not found." )
ELSE ( NOT SWIG_EXECUTABLE )
  MESSAGE( STATUS "SWIG found at ${SWIG_EXECUTABLE}" )
ENDIF ( NOT SWIG_EXECUTABLE )

#
# Where is YaST ?
#

FIND_PACKAGE(Yast REQUIRED)
IF ( NOT YAST_LIBRARY )
  MESSAGE( FATAL_ERROR "Please install yast2-core-devel." )
ENDIF ( NOT YAST_LIBRARY )

IF ( NOT YAST_PLUGIN_UI_LIBRARY )
  MESSAGE( FATAL_ERROR "YAST_PLUGIN_UI_LIBRARY not set, please install yast2-ycp-ui-bindings-devel." )
ENDIF ( NOT YAST_PLUGIN_UI_LIBRARY )

#
# Where is Ruby ?
#

FIND_PACKAGE(Ruby REQUIRED)
IF ( NOT RUBY_EXECUTABLE )
  MESSAGE( FATAL_ERROR "Ruby not found." )
ENDIF ( NOT RUBY_EXECUTABLE )

#
# -> src/
#

ADD_SUBDIRECTORY(src)

#
# packaging
#
SET( RPMNAME "yast2-ruby-bindings" )

GENERATE_PACKAGING(${RPMNAME} ${VERSION})
