add_definitions(-DY2LOG=\"Ruby\")

set(yast_ruby_module_SRCS
  Yast.cc
  Y2RubyTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  Y2YCPTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  Y2RubyReference.cc
  Y2RubyUtils.cc
)

set(builtin_ruby_module_SRCS
  Builtin.cc
  Y2RubyTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  Y2YCPTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  Y2RubyReference.cc
  RubyLogger.cc
)

set(ruby_yast_plugin_SRCS
  Y2CCRuby.cc
  Y2CCRubyClient.cc
  Y2RubyComponent.cc
  Y2RubyClientComponent.cc
  YRuby.cc
  YRubyNamespace.cc
  Y2RubyTypeConv.cc
  Y2YCPTypeConv.cc
  Y2RubyReference.cc
  Y2RubyUtils.cc
)

set(ruby_yast_plugin_HEADERS
  Y2CCRuby.h
  Y2CCRubyClient.h
  Y2RubyComponent.h
  Y2RubyClientComponent.h
  YRuby.h
  YRubyNamespace.h
  Y2RubyUtils.h
)

include_directories( ${RUBY_INCLUDE_PATH} )
#include also arch specific config.h
include_directories( ${RUBY_HEADER_DIR}/${RUBY_ARCH} )
include_directories( ${YAST_INCLUDE_DIR} )

link_directories(${YAST_PLUGIN_DIR})

add_definitions(${CC_FLAGS} -Wno-deprecated)

#
# Ruby -> YCP/YaST
# yast.rb + yastx.so
#


add_library(yastx SHARED ${yast_ruby_module_SRCS})
add_library(builtinx SHARED ${builtin_ruby_module_SRCS})
# libyastx.so -> yastx.so
set_target_properties(yastx PROPERTIES PREFIX "")
set_target_properties(builtinx PROPERTIES PREFIX "")

#
# Use rpath to find YaST plugin libs (wfm has static constructors :-( )
#
# According to http://www.cmake.org/Wiki/CMake_RPATH_handling(Always full RPATH,
# tight control) CMake should be able to handle this. However, it somehow does
# not work.
#
# jreidinger: new cmake start stripping it, so it need to be explicitelly added
set_target_properties( yastx PROPERTIES INSTALL_RPATH "${YAST_PLUGIN_DIR}")
set_target_properties( builtinx PROPERTIES INSTALL_RPATH "${YAST_PLUGIN_DIR}")
#
# So using an explicit linker option instead:
# (http://www.cmake.org/pipermail/cmake/2008-January/019321.html)
#
SET ( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-rpath,'${YAST_PLUGIN_DIR}'" )

target_link_libraries( yastx ${YAST_LIBRARY} )
target_link_libraries( yastx ${YAST_YCP_LIBRARY} )
target_link_libraries( yastx ${YAST_PLUGIN_UI_LIBRARY} )
#
# The WFM and SCR component can only be initialized statically
# (e.g. through Y2CCWFM), thus we must link against the plugin libs
# and set the executables 'rpath' accordingly
#
target_link_libraries( yastx ${RUBY_LIBRARY} )

target_link_libraries( builtinx ${YAST_LIBRARY} )
target_link_libraries( builtinx ${YAST_YCP_LIBRARY} )
target_link_libraries( builtinx ${YAST_PLUGIN_SCR_LIBRARY} )
target_link_libraries( builtinx ${YAST_PLUGIN_WFM_LIBRARY} )
target_link_libraries( builtinx ${YAST_PLUGIN_UI_LIBRARY} )
target_link_libraries( builtinx crypt )
find_library( OWCRYPT_LIBRARY owcrypt )
if ( OWCRYPT_LIBRARY )
  target_link_libraries( builtinx ${OWCRYPT_LIBRARY} )
endif()

install(TARGETS yastx LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR} )
install(TARGETS builtinx LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR}/yast )

#
# YCP -> Ruby
# libpy2lang_ruby (YCP plugin library)
#

add_library( py2lang_ruby SHARED ${ruby_yast_plugin_SRCS})
target_link_libraries( py2lang_ruby ${YAST_LIBRARY} )
target_link_libraries( py2lang_ruby ${YAST_YCP_LIBRARY} )
target_link_libraries( py2lang_ruby ${YAST_PLUGIN_WFM_LIBRARY} )
target_link_libraries( py2lang_ruby ${RUBY_LIBRARY} )
set_target_properties( py2lang_ruby PROPERTIES INSTALL_RPATH "${YAST_PLUGIN_DIR}")
install(TARGETS py2lang_ruby LIBRARY DESTINATION ${YAST_PLUGIN_DIR} )
