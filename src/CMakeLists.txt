add_subdirectory(ruby)
add_subdirectory(binary)
add_subdirectory(bin)

# rdoc
set(rdoc_dir "${CMAKE_CURRENT_BINARY_DIR}/html")
ADD_CUSTOM_COMMAND (
   OUTPUT ${rdoc_dir}
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating rdoc documentation ..."
   COMMAND rm -rf ${rdoc_dir}
   COMMAND rdoc -o ${rdoc_dir} ruby binary/YCP.cc
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/src/
   DEPENDS ${CMAKE_SOURCE_DIR}/src/binary/YCP.cc ${CMAKE_SOURCE_DIR}/src/ruby/*.rb
)
add_custom_target(rdoc ALL DEPENDS "${rdoc_dir}")
add_dependencies(rdoc ycpx)
add_dependencies(rdoc scrx)
