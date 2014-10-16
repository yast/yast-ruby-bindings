# Yast2-ruby-bindings
It is part of [YaST2](http://yast.github.io) where you can find more information
about YaST2 and its component system. Ruby bindings covers only connection to
component system and provide some ruby helpers.

## Features

### Publish, Import and Include
Connection to YaST2 component system has two parts. The first one is ability
to be called from component system. Clients can be called via WFM (see below )
and modules provide interface via publish method, where is specified type.
Publish is very similar to dbus interface provision. For more details see inline
documentation of {Yast::Exportable#publish}.

The second part is calling methods from component system. Clients are called
via WMF (see below). Methods from modules are imported with {Yast.import}, that
load component and create ruby object in Yast namespace from it, on which can be
called exported methods. Note that calling from ruby to ruby published methods
are optimized, so it do not go thrue component system resulting in no speed
penalty.

```ruby
# how to import module and call it
require "yast"
Yast.import "IP"
puts Yast::IP.Valid4
```

Relict from transformation from ycp to ruby is {Yast.include} which adds methods
from included class to passed object. It is very similar to ruby `include` with
exception that Include object can include others Include object and that there
is special constructor instead of common ruby `included`.

### Ruby Helpers
Ruby bindings provides set of various helpers for work with YaST2 component
system or to make translation from ycp to ruby easier. Here is overview of 
important provided classes with link to inline documentation and short explanation:

* {Yast::ArgRef} class to be used for passing arguments by reference. Works
  even for ruby immutable types like Fixnum or Symbol.
* {Yast::Builtins} module contains ycp builtins that need to be simulated in
  ruby. For new code it should not be used.
* {Yast::Client} base class for clients in ruby. It is not required.
  Just add helpers.
* {Yast::Convert} simulate type conversion. Not needed in new code.
* {Yast::Exportable} provides method publish ( see above )
* {Yast::FunRef} container used to pass reference to method to component system.
* {Yast::I18n} Provides methods used for translations.
* {Yast::Module} base class for YaST2 modules in ruby. It is not required.
  Just add helpers.
* {Yast::Ops} module contains ycp operators that need to be simulated in
  ruby. For new code it should not be used.
* {Yast::Path} represents path type from component system.
* {Yast::SCR} allows usage of SCR component for communication with system.
* {Yast::Term} represents term type from component system. Often used for UI.
* {Yast::WFM} allows usage of WFM component. WFM is used to call clients, gets
  argument from call and for setting new SCR instance as global one.
* {Yast::Y2Logger} ruby logger configured to work like yast log with proper
  place to use.
* {Yast} namespace itself contains few helpers to be used. It contains 
  shortcuts and method for deep copy of object.

### UI Shortcuts
{Yast::UIShortcuts} provides shortcut to UI terms. It is useful to construct
dialogs or even popups.

```ruby
# usage with term
content = Yast::Term.new(
  :ButtonBox,
  Yast::Term.new(
    :PushButton,
    Yast::Term.new(:id, :ok_button),
    "OK"
  )
  Yast::Term.new(
    :PushButton,
    Yast::Term.new(:id, :cancel_button),
    "Cancel"
  )
)

# usage with shortcuts
include Yast::UIShortcuts
content = ButtonBox(
  PushButton(Id(:ok_button), "OK"),
  PushButton(Id(:cancel_button), "Cancel")
)
```

### Testing
YaST2 team encourages to use rspec for testing YaST code in ruby. There is
a plan to create helper to allow easier testing.

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
