
ADD_DEFINITIONS(-DY2LOG=\\\"Ruby\\\")

SET(yast_ruby_module_SRCS
  YCP.cc
  Y2RubyTypeConv.cc
  RubyLogger.cc
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
)
  
SET(ruby_yast_plugin_HEADERS
  RubyLogger.h
  Y2CCRuby.h
  Y2RubyComponent.h
  YRuby.h
  YRubyNamespace.h
  Y2RubyTypePath.h
  Y2RubyTypeTerm.h
)

# skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  TRUE)
# when building, use the install RPATH already
# (so it doesn't need to relink when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE) 
# the RPATH to be used when installing
SET(CMAKE_INSTALL_RPATH "${LIB_INSTALL_DIR}/YaST2/plugins")
# add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
  
INCLUDE_DIRECTORIES( ${RUBY_INCLUDE_PATH} )
INCLUDE_DIRECTORIES( ${YAST_INCLUDE_DIR} )
  
ADD_LIBRARY( ycpx SHARED ${yast_ruby_module_SRCS})
SET_TARGET_PROPERTIES( ycpx PROPERTIES PREFIX "" )
TARGET_LINK_LIBRARIES( ycpx ${YAST_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${YAST_YCP_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${YAST_PLUGIN_WFM_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${YAST_PLUGIN_SCR_LIBRARY} )
TARGET_LINK_LIBRARIES( ycpx ${RUBY_LIBRARY} )
INSTALL(TARGETS ycpx LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR} )

INSTALL(FILES ${CMAKE_CURRENT_SOURCE_DIR}/ycp.rb DESTINATION ${RUBY_VENDORLIB_DIR} )

ADD_LIBRARY( py2lang_ruby SHARED ${ruby_yast_plugin_SRCS})
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_YCP_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${YAST_PLUGIN_WFM_LIBRARY} )
TARGET_LINK_LIBRARIES( py2lang_ruby ${RUBY_LIBRARY} )
INSTALL(TARGETS py2lang_ruby LIBRARY DESTINATION ${YAST_PLUGIN_DIR} )

#SET_TARGET_PROPERTIES( y2lang_ruby PROPERTIES PREFIX "" )