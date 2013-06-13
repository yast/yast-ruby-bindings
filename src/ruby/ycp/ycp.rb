require "ycpx"

#predefine term to avoid circular dependency
class YCP::Term;end
class YCP::FunRef;end
class YCP::YReference;end
class YCP::Path;end

module YCP

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
    when YCP::FunRef, YCP::ArgRef, YCP::External, YCP::YReference #contains only reference somewhere
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
    YCP.deep_copy(object)
  end
  alias_method :copy_arg, :deep_copy

  def self.include(target, path)
    path_without_suffix = path.sub("\.rb$","")
    module_name = path_without_suffix.
      gsub(/^./)     { |s| s.upcase }.
      gsub(/\/./)    { |s| "::" + s[1].upcase }.
      gsub(/[-_.]./) { |s| s[1].upcase } +
      "Include"

    name_parts = module_name.split("::")

    parent = YCP
    loaded = name_parts.all? do |name_part|
      next false unless parent.constants.include? name_part.to_sym
      parent = parent.const_get name_part
    end

    unless loaded
      path = find_include_file path
      require path
    end

    mod = name_parts.reduce(YCP) do |parent, module_name|
      YCP.const_get module_name
    end

    return if target.class.include? mod

    target.class.send(:include, mod)

    method_name = "initialize_" + path_without_suffix.gsub(/[.-\/]/, "_")

    target.send method_name.to_sym, target
  end

  def self.import(mname)
    modules = mname.split("::")

    base = YCP
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
            return YCP::call_ycp_function("#{mname}", :#{sname}, *args)
          end
        END
      end
      if stype == :variable
        m.module_eval <<-"END"
          def self.#{sname}
            return YCP::call_ycp_function("#{mname}", :#{sname})
          end
          def self.#{sname}= (value)
            return YCP::call_ycp_function("#{mname}", :#{sname}, value)
          end
        END
      end
    end

    base.const_set(modules.last, m)
  end

end


