require "yastx"

#predefine term to avoid circular dependency
class Yast::Term;end
class Yast::FunRef;end
class Yast::YReference;end
class Yast::Path;end

module Yast

  def term(*args)
    return Term.new *args
  end

  def fun_ref(*args)
    return FunRef.new *args
  end

  def arg_ref(*args)
    return ArgRef.new *args
  end

  def path(*args)
    return Path.new *args
  end

  #makes copy of object unless object is immutable. In such case return object itself
  def self.deep_copy object
    case object
    when Numeric,TrueClass,FalseClass,NilClass,Symbol #immutable
      object
    when Yast::FunRef, Yast::ArgRef, Yast::External, Yast::YReference #contains only reference somewhere
      object
    when ::Hash
      object.reduce({}) do |acc,kv|
        acc[deep_copy(kv[0])] = deep_copy(kv[1])
        acc
      end
    when ::Array
       object.reduce([]) do |acc,v|
        acc << deep_copy(v)
      end
    else
      object.clone #deep copy
    end
  end

#makes copy of object unless object is immutable. In such case return object itself
  def deep_copy object
    Yast.deep_copy(object)
  end
  alias_method :copy_arg, :deep_copy

  def self.include(target, path)
    path_without_suffix = path.sub(/\.rb$/,"")
    module_name = path_without_suffix.
      gsub(/^./)     { |s| s.upcase }.
      gsub(/\/./)    { |s| s[1].upcase }.
      gsub(/[-_.]./) { |s| s[1].upcase } +
      "Include"

    loaded = Yast.constants.include? module_name.to_sym

    unless loaded
      path = find_include_file path
      require path
    end

    mod = Yast.const_get module_name

    return if target.class.include? mod

    target.class.send(:include, mod)

    method_name = "initialize_" + path_without_suffix.gsub(/[.-\/]/, "_")

    target.send method_name.to_sym, target
  end

  def self.import(mname)
    modules = mname.split("::")

    base = Yast
    # Handle multilevel modules like YaPI::Network
    modules[0..-2].each do |module_|
      tmp_m = if base.constants.include?(module_.to_sym)
          base.const_get(module_)
        else
          base.const_set(module_, ::Module.new)
        end
      base = tmp_m
    end

    # do not reimport if already imported
    return if base.constants.include?(modules.last.to_sym)

    import_pure(mname)

    # do not create wrapper if module is in ruby and define itself object
    return if base.constants.include?(modules.last.to_sym)

    m = ::Module.new
    symbols(mname).each do |sname,stype|
      next if sname.empty?
      if (stype == :function)
        m.module_eval <<-"END"
          def self.#{sname}(*args)
            return Yast::call_yast_function("#{mname}", :#{sname}, *args)
          end
        END
      end
      if stype == :variable
        m.module_eval <<-"END"
          def self.#{sname}
            return Yast::call_yast_function("#{mname}", :#{sname})
          end
          def self.#{sname}= (value)
            return Yast::call_yast_function("#{mname}", :#{sname}, value)
          end
        END
      end
    end

    base.const_set(modules.last, m)
  end

end


