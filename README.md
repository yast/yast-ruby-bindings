# Yast2-ruby-bindings

Travis:  [![Build Status](https://travis-ci.org/yast/yast-ruby-bindings.svg?branch=master)](https://travis-ci.org/yast/yast-ruby-bindings)
Jenkins: [![Jenkins Build](http://img.shields.io/jenkins/s/https/ci.opensuse.org/yast-ruby-bindings-master.svg)](https://ci.opensuse.org/view/Yast/job/yast-ruby-bindings-master/)

It is part of [YaST](http://yast.github.io) where you can find more information
about YaST and its component system. The Ruby bindings cover only the connection to
the component system and provide some Ruby helpers.

It started as an experimental project to allow writting in Ruby, but after a decision
to switch from an own language YCP to Ruby, it is a major part of YaST needed by
almost all parts. As a relict from the language switch it contains constructs
to keep backward compatibility which need a human decision before being removed.

## Features

### Publish, Import and Include

The connection to the [YaST component system][arch] has two parts.
The first one is the ability
to be called from the component system. *Clients* can be called via WFM (see below )
and *modules* provide an interface via the `publish` method, where the type
signature is specified.
Publish is very similar to dbus interface provision. For more details see inline
documentation of {Yast::Exportable#publish}. If a method is needed only from Ruby,
then `publish` is not needed.

[arch]: https://yastgithubio.readthedocs.org/en/latest/architecture/

The second part is calling methods from the component system. *Clients* are called
via WFM (see below). Methods from *modules* are imported with {Yast.import}, which
loads a component and creates a Ruby object in the Yast namespace from it, on which
exported methods can be called.
Note that if a call is done from Ruby to Ruby, then it is not limited
by the component
system and its protocol, so all Ruby features can be used.

```ruby
# how to import a module and call it
require "yast"
Yast.import "IP"
puts Yast::IP.Check4("127.0.0.333")
```

A relict from the transformation from YCP to Ruby is {Yast.include} which adds methods
from the included class to passed object. It is very similar to Ruby `include` with
the exception that an Include object can include other Include objects and thus there is
a special constructor instead of common Ruby `included`.

### Ruby Helpers

Ruby bindings provide a set of various helpers for working with the YaST component
system or for making the translation from YCP to Ruby easier. Here is an overview of
important provided classes with links to the inline documentation and a short explanation:

* {Yast::ArgRef}: a class to be used for passing arguments by reference. Works
  even for Ruby immutable types like Fixnum or Symbol.
* {Yast::Builtins}: this module contains YCP builtins that need to be simulated in
  Ruby. For new code it should not be used.
* {Yast::Client}: a base class for clients in Ruby. It is not strictly
  required to inherit from it, but it adds useful helpers.
* {Yast::Convert}: simulates type conversion. Not needed in new code.
* {Yast::Exportable}: provides the method `publish` (see above).
* {Yast::FunRef}: a container used to pass references to methods to the component system.
* {Yast::I18n}: provides methods used for translations.
* {Yast::Module}: a base class for YaST modules in Ruby. It is not strictly
  required to inherit from it, but it adds useful helpers.
* {Yast::Ops}: this module contains YCP operators that need to be simulated in
  Ruby. For new code it should not be used.
* {Yast::Path}: represents the path type from the YCP protocol.
* {Yast::SCR}: allows usage of SCR component for communication with the Linux system.
* {Yast::Term}: represents the term type from the YCP protocol. Often used for UI.
* {Yast::WFM}: allows usage of WFM component. WFM is used for calling clients,
  and for setting a new SCR instance as the global one.
* {Yast::Y2Logger}: a Ruby Logger configured to work with the YaST log with proper
  place to use. The Ruby module {Yast::Logger} provides easy access via the method
  `log`.
* {Yast}: the namespace itself contains a few helpers to be used. It contains
  shortcuts and a method for a deep copy of an object.

### UI Shortcuts

{Yast::UIShortcuts} provides shortcuts for UI terms. It is useful to construct
dialogs or even popups.

```ruby
# usage with Term
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

The YaST team encourages to use RSpec for testing YaST code in Ruby. To help in
that task, this gem includes some RSpec extensions under the {Yast::RSpec}
namespace. In order to use these extensions, the following line must be added
to the tests.

```ruby
require 'yast/rspec'
```

For example, the following code makes use of the #path helper provided by
{Yast::RSpec::Shortcuts}.

```ruby

require 'yast/rspec'

describe ".proc.meminfo agent" do
  it "returns a Hash" do
    value = Yast::SCR.Read(path(".proc.meminfo"))
    expect(value).to be_a(Hash)
  end
end
```

### Further Information

More information about YaST can be found on its [homepage](http://yast.github.io).
More information about Ruby bindings can be found in the generated documentation.

## Packager information

### How to Compile

Use the latest yast2-devtools, then use these calls:

```bash
mkdir build
cd build
cmake ..
make
```

### How to Install

Compile it, and from the `build` directory call as root:

```bash
make install
```

### How to Create a Tarball

```bash
rake package
```

Then the RPM sources are in the `package` subdirectory.

### Exception handling

If Ruby code raises an exception, then the method returns `nil` to YCP,
and the method `last_exception` returns the message of the exception.
Also, exception details are logged.
