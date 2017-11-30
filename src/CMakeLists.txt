add_subdirectory(ruby)
add_subdirectory(binary)

install(PROGRAMS y2start/y2start DESTINATION lib/YaST2/bin)

# hardcode the ruby version in the y2start script (bsc#1068863)
# use bash -c to expand $DESTDIR
install(CODE "execute_process(COMMAND bash -c \"echo Updating $DESTDIR${CMAKE_INSTALL_PREFIX}/lib/YaST2/bin/y2start:\")")
# replace the first line in y2start with a new hashbang
install(CODE "execute_process(COMMAND bash -c \"sed -i '1 s@^.*$@\\#! ${RUBY_BIN_PATH}@' $DESTDIR${CMAKE_INSTALL_PREFIX}/lib/YaST2/bin/y2start\")")
install(CODE "execute_process(COMMAND bash -c \"head -n1 $DESTDIR${CMAKE_INSTALL_PREFIX}/lib/YaST2/bin/y2start\")")
