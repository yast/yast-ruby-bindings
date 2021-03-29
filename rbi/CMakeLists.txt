file(GLOB files "${CMAKE_CURRENT_SOURCE_DIR}/yast/*.rbi")

install(FILES ${files} DESTINATION share/YaST2/rbi/yast)
