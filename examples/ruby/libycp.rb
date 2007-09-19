require 'ryast'
include Ryast

def get_ns(name)
  import = Import.new(name)
  ns = import.name_space
  puts ns.filename
  #ns.initialize

  return ns
end

component = Y2ComponentBroker.get_namespace_component("Arch");
#puts component.methods
#Y2Namespace *ns = c->import(RSTRING (namespace_name)->ptr);
nsname = "Arch"
fncname = "sparc32"
ns = get_ns(nsname)
#/**/
#t = Type.from_signature("bool()")
#puts t
sym = ns.table.find(fncname);
puts sym.class
if (sym.nil?)
  raise ("No such symbol #{nsname}::#{fncname}")
elsif (sym.sentry.is_variable or sym.sentry.reference? )
  # set the variable
  #ret_yv = YCP_getset_variable (aTHX_ ns_name, sym_te->sentry (), args);
else
  fnccall = ns.create_function_call(fncname, nil)
  if fnccall.nil?
    raise("No such function #{nsname}::#{fncname}")
  end
end
exit

h = ns.lookup_symbol("sparc32")
puts h.class
exit
function = ns.create_function_call("sparc32",0)
#call->appendParameter (v);
function.finish_parameters
res = function.evaluate_call
puts res
exit
