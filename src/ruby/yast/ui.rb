# This is a counterpart to init_ui in the C code.
# It really belongs near it but I don't know how to code a proc in C.
# Workaround warning in ruby3. See e.g. https://github.com/appsignal/rdkafka-ruby/pull/160/files#r656637223
mod = Yast
ObjectSpace.define_finalizer(mod, proc { mod.ui_finalizer })
