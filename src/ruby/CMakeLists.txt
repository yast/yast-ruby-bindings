
ADD_DEFINITIONS(-DY2LOG=\\\"Ruby\\\")

SET(yast_ruby_module_SRCS
  YCP.cc
  Y2RubyTypePath.cc       # YCP.cc -> ryast_path_init()
  Y2RubyTypeTerm.cc       # YCP.cc -> ryast_term_init()
  Y2RubyTypeConv.cc       # YCP.cc -> ycpvalue_2_rbvalue(), rbvalue_2_ycpvalue()
  RubyLogger.cc
  Y2RubyUtils.cc
  RubyLogger.h
)

SET(ruby_yast_plugin_SRCS
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
  
SET(ruby_yast_plugin_HEADERS
  RubyLogger.h
  Y2CCRuby.h
  Y2RubyComponent.h
  YRuby.h
  YRubyNamespace.h
  Y2RubyUtils.h
  Y2RubyTypePath.h
  Y2RubyTypeTerm.h
)

INCLUDE_DIRECTORIES( ${RUBY_INCLUDE_PATH} )
INCLUDE_DIRECTORIES( ${YAST_INCLUDE_DIR} )

LINK_DIRECTORIES(${YAST_PLUGIN_DIR})

ADD_DEFINITIONS( ${CC_FLAGS} -Wno-deprecated)

#
# Ruby -> YCP/YaST
# ycp.rb + ycpx.so
#


ADD_LIBRARY( ycpx SHARED ${yast_ruby_module_SRCS})
SET_TARGET_PROPERTIES( ycpx PROPERTIES PREFIX "" )

#
# Use rpath to find YaST plugin libs (wfm has static constructors :-( )
#
# According to http://www.cmake.org/Wiki/CMake_RPATH_handling(Always full RPATH,
# tight control) CMake should be able to handle this. However, it somehow does
# not work.
#
#SET_TARGET_PROPERTIES( ycpx PROPERTIES SKIP_BUILD_RPATH FALSE)
#SET_TARGET_PROPERTIES( ycpx PROPERTIES BUILD_WITH_INSTALL_RPATH FALSE) 
#SET_TARGET_PROPERTIES( ycpx PROPERTIES INSTALL_RPATH_USE_LINK_PATH FALSE)
#SET_TARGET_PROPERTIES( ycpx PROPERTIES INSTALL_RPATH "${YAST_PLUGIN_DIR}")
#
# So using an explicit linker option instead:
# (http://www.cmake.org/pipermail/cmake/2008-January/019321.html)
#
SET ( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-rpath,'${YAST_PLUGIN_DIR}'" )

TARGET_LINK_LIBRARIES( ycpx ${YAST_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${YAST_YCP_LIBRARY} )
#
# The WFM and SCR component can only be initialized statically
# (e.g. through Y2CCWFM), thus we must link against the plugin libs
# and set the executables 'rpath' accordingly
#
TARGET_LINK_LIBRARIES( ycpx ${YAST_PLUGIN_WFM_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${YAST_PLUGIN_SCR_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${RUBY_LIBRARY} )


INSTALL(TARGETS ycpx LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR} )

INSTALL(FILES ${CMAKE_CURRENT_SOURCE_DIR}/ycp.rb DESTINATION ${RUBY_VENDORLIB_DIR} )

# rdoc
SET(rdoc_dir "${CMAKE_CURRENT_BINARY_DIR}/html")
ADD_CUSTOM_COMMAND (
   OUTPUT ${rdoc_dir}
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating rdoc documentation ..."
   COMMAND rm -rf ${rdoc_dir}
   COMMAND rdoc -o ${rdoc_dir} ycp.rb YCP.cc
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/src/ruby
   DEPENDS ${CMAKE_SOURCE_DIR}/src/ruby/YCP.cc ${CMAKE_SOURCE_DIR}/src/ruby/*.rb
)
ADD_CUSTOM_TARGET(ruby_rdoc ALL DEPENDS "${rdoc_dir}")
ADD_DEPENDENCIES(ruby_rdoc ycpx)

#
# YCP -> Ruby
# libpy2lang_ruby (YCP plugin library)
#

ADD_LIBRARY( py2lang_ruby SHARED ${ruby_yast_plugin_SRCS})
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_YCP_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_PLUGIN_WFM_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${RUBY_LIBRARY} )
INSTALL(TARGETS py2lang_ruby LIBRARY DESTINATION ${YAST_PLUGIN_DIR} )

#SET_TARGET_PROPERTIES( y2lang_ruby PROPERTIES PREFIX "" )
