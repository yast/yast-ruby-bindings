# Yast2-ruby-bindings
The bindings allow YaST modules to be written using the Ruby language and also Ruby scripts can use YaST agents, APIs and modules.

## Packager information
### How to compile
Use latest yast2-devtools. then use this calls:
```
mkdir build
cd build
cmake ..
make
```

### How to install
Compile it and from build directory call as root
```
make install
```

### How to create tarball
compile and from build directory call
```
make srcpackage
```
Then in package subdir is sources.


### Exception handling
When ruby code raise exception, then method return `nil` in YCP and add method last_exception, that returns message of exception. Also exception details are logged.
