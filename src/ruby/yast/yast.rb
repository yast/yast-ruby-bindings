require "yastx"

#predefine term to avoid circular dependency
class Yast::Term;end
class Yast::FunRef;end
class Yast::YReference;end
class Yast::Path;end

module Yast

  # @private used to extract place from backtrace
  BACKTRACE_REGEXP = /^(.*):(\d+):in `.*'$/

  # shortcut to construct new Yast term
  # @see Yast::Term
  def term(*args)
    return Term.new *args
  end

  # shortcut to construct new function reference
  # @see Yast::FunRef
  def fun_ref(*args)
    return FunRef.new *args
  end

  # shortcut to construct new argument reference
  # @see Yast::ArgRef
  def arg_ref(*args)
    return ArgRef.new *args
  end

  # shortcut to construct new Yast path
  # @see Yast::Path
  def path(*args)
    return Path.new *args
  end

  # Makes deep copy of object. Difference to #dup or #clone is that it copy all elements of Array, Hash, Yast::Term.
  # Immutable classes is just returned.
  # @param [Hash] options modifies behavior
  # @option options [TrueClass,FalseClass] :full (false) make full copy even for types that is immutable in Yast builtins context
  # @note String, Yast::Path and Yast::Byteblock is also immutable in sense of Yast because there is no builtin operation for string modify that do not copy it. Use :full option to copy it also.
  # @example how to refactor generated code
  #   #old method where a is not need to copy and b is needed, but we plan to use full ruby features to modify strings
  #   def old(a, b)
  #     a = copy_arg(a)
  #     b = copy_arg(b)
  #     ...
  #   end
  #
  #   #refactored method
  #   def new(a, b)
  #     b = copy_arg b, :full => true
  #     ...
  #   end
  def self.deep_copy object, options = {}
    case object
    when Numeric,TrueClass,FalseClass,NilClass,Symbol #immutable
      object
    when ::String, Yast::Path, Yast::Byteblock #immutable in sense of yast buildins
      options[:full] ? object.clone : object
    when Yast::FunRef, Yast::ArgRef, Yast::External, Yast::YReference, Yast::YCode #contains only reference somewhere
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

  # Shortcut for Yast::deep_copy
  # @see Yast.deep_copy
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

    method_name = "initialize_" + path_without_suffix.gsub(/[-.\/]/, "_")

    target.send method_name.to_sym, target if target.respond_to? method_name.to_sym
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

    # do not reimport if already imported and contain some methods
    # ( in case namespace contain some methods )
    if base.constants.include?(modules.last.to_sym) &&
        !(base.const_get(modules.last).methods - Object.methods()).empty?
      return
    end

    import_pure(mname)

    # do not create wrapper if module is in ruby and define itself object
    if base.constants.include?(modules.last.to_sym) &&
        !(base.const_get(modules.last).methods - Object.methods()).empty?
      return
    end

    m = if base.constants.include?(modules.last.to_sym)
        base.const_get(modules.last)
      else
        ::Module.new
      end
    symbols(mname).each do |sname,stype|
      next if sname.empty?
      if (stype == :function)
        m.module_eval <<-"END"
          def self.#{sname}(*args)
            caller[0].match BACKTRACE_REGEXP
            return Yast::call_yast_function("#{mname}", :#{sname}, $1, $2.to_i, *args)
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

    base.const_set(modules.last, m) unless base.constants.include?(modules.last.to_sym)
  end

end


