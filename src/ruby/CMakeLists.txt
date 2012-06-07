add_definitions(-DY2LOG=\"Ruby\")

set(yast_ruby_module_SRCS
  YCP.cc
  Y2RubyTypePath.cc       # YCP.cc -> ryast_path_init()
  Y2RubyTypeTerm.cc       # YCP.cc -> ryast_term_init()
  Y2RubyTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  RubyLogger.cc
  Y2RubyUtils.cc
  RubyLogger.h
)

set(ruby_yast_plugin_SRCS
  RubyLogger.cc
  Y2CCRuby.cc
  Y2RubyComponent.cc
  YRuby.cc
  YRubyNamespace.cc
  Y2RubyTypeConv.cc
  Y2RubyTypePath.cc
  Y2RubyTypeTerm.cc
  Y2RubyUtils.cc
)
  
set(ruby_yast_plugin_HEADERS
  RubyLogger.h
  Y2CCRuby.h
  Y2RubyComponent.h
  YRuby.h
  YRubyNamespace.h
  Y2RubyUtils.h
  Y2RubyTypePath.h
  Y2RubyTypeTerm.h
)

include_directories( ${RUBY_INCLUDE_PATH} )
#include also arch specific config.h
include_directories( ${RUBY_HEADER_DIR}/${RUBY_ARCH} )
include_directories( ${YAST_INCLUDE_DIR} )

link_directories(${YAST_PLUGIN_DIR})

add_definitions(${CC_FLAGS} -Wno-deprecated)

#
# Ruby -> YCP/YaST
# ycp.rb + ycpx.so
#


add_library(ycpx SHARED ${yast_ruby_module_SRCS})
# libycpx.so -> ycpx.so
set_target_properties(ycpx PROPERTIES PREFIX "")

#
# Use rpath to find YaST plugin libs (wfm has static constructors :-( )
#
# According to http://www.cmake.org/Wiki/CMake_RPATH_handling(Always full RPATH,
# tight control) CMake should be able to handle this. However, it somehow does
# not work.
#
#set_target_properties( ycpx PROPERTIES SKIP_BUILD_RPATH FALSE)
#set_target_properties( ycpx PROPERTIES BUILD_WITH_INSTALL_RPATH FALSE) 
#set_target_properties( ycpx PROPERTIES INSTALL_RPATH_USE_LINK_PATH FALSE)
#set_target_properties( ycpx PROPERTIES INSTALL_RPATH "${YAST_PLUGIN_DIR}")
#
# So using an explicit linker option instead:
# (http://www.cmake.org/pipermail/cmake/2008-January/019321.html)
#
SET ( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-rpath,'${YAST_PLUGIN_DIR}'" )

target_link_libraries( ycpx ${YAST_LIBRARY} )
target_link_libraries( ycpx ${YAST_YCP_LIBRARY} )
#
# The WFM and SCR component can only be initialized statically
# (e.g. through Y2CCWFM), thus we must link against the plugin libs
# and set the executables 'rpath' accordingly
#
target_link_libraries( ycpx ${YAST_PLUGIN_WFM_LIBRARY} )
target_link_libraries( ycpx ${YAST_PLUGIN_SCR_LIBRARY} )
target_link_libraries( ycpx ${YAST_PLUGIN_UI_LIBRARY} )
target_link_libraries( ycpx ${RUBY_LIBRARY} )


install(TARGETS ycpx LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR} )

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/ycp.rb DESTINATION ${RUBY_VENDORLIB_DIR} )

# rdoc
set(rdoc_dir "${CMAKE_CURRENT_BINARY_DIR}/html")
ADD_CUSTOM_COMMAND (
   OUTPUT ${rdoc_dir}
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating rdoc documentation ..."
   COMMAND rm -rf ${rdoc_dir}
   COMMAND rdoc -o ${rdoc_dir} ycp.rb YCP.cc
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/src/ruby
   DEPENDS ${CMAKE_SOURCE_DIR}/src/ruby/YCP.cc ${CMAKE_SOURCE_DIR}/src/ruby/*.rb
)
add_custom_target(ruby_rdoc ALL DEPENDS "${rdoc_dir}")
add_dependencies(ruby_rdoc ycpx)

#
# YCP -> Ruby
# libpy2lang_ruby (YCP plugin library)
#

add_library( py2lang_ruby SHARED ${ruby_yast_plugin_SRCS})
target_link_libraries( py2lang_ruby ${YAST_LIBRARY} )
target_link_libraries( py2lang_ruby ${YAST_YCP_LIBRARY} )
target_link_libraries( py2lang_ruby ${YAST_PLUGIN_WFM_LIBRARY} )
target_link_libraries( py2lang_ruby ${RUBY_LIBRARY} )
install(TARGETS py2lang_ruby LIBRARY DESTINATION ${YAST_PLUGIN_DIR} )
