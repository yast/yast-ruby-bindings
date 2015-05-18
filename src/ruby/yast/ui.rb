module Yast
  # This is a counterpart to init_ui in the C code.
  # It really belongs near it but I don't know how to code a proc in C.
  ObjectSpace.define_finalizer(Yast, proc { Yast.ui_finalizer } )
end
