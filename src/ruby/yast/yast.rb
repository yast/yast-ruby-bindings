require "yastx"

module Yast
  # predefine term to avoid circular dependency
  class Term; end
  class FunRef; end
  class YReference; end
  class Path; end

  # Custom exception class to indicate the process should abort
  # without any more user interaction.
  #
  # It avoids to show the dialog to handle a general exception
  # with options as to launch a debugger.
  class AbortException < RuntimeError
  end

  # @private used to extract place from backtrace
  BACKTRACE_REGEXP = /^(.*):(\d+):in [`'].*'$/

  # shortcut to construct new Yast term
  # @see Yast::Term
  module_function def term(*args)
    Term.new(*args)
  end

  # shortcut to construct new function reference
  # @see Yast::FunRef
  module_function def fun_ref(*args)
    FunRef.new(*args)
  end

  # shortcut to construct new argument reference
  # @see Yast::ArgRef
  module_function def arg_ref(*args)
    ArgRef.new(*args)
  end

  # shortcut to construct new Yast path
  # @param value [String, Yast::Path] value of path. If it is path, it will
  #   return itself. For String it will return new Yast::Path instance
  #   initialized from it.
  # @see Yast::Path
  module_function def path(value)
    case value
    when Yast::Path
      value
    when ::String
      Path.new(value)
    else
      raise ArgumentError, "Argument #{value.inspect} is neither a ::String or a Yast::Path"
    end
  end

  # Makes deep copy of object. Difference to #dup or #clone is
  # that it copy all elements of Array, Hash, Yast::Term.
  # Immutable classes is just returned.
  # @param [Hash] options modifies behavior
  # @option options [TrueClass,FalseClass] :full (false) make full copy
  #   even for types that is immutable in Yast builtins context
  # @note String, Yast::Path and Yast::Byteblock is also immutable
  #   in sense of Yast because there is no builtin operation
  #   for string modify that do not copy it. Use :full option to copy it also.
  # @example how to refactor generated code
  #   # old method where a is not need to copy
  #   # and b is needed, but we plan to use full ruby features to modify strings
  #   def old(a, b)
  #     a = copy_arg(a)
  #     b = copy_arg(b)
  #     ...
  #   end
  #
  #   # refactored method
  #   def new(a, b)
  #     b = copy_arg b, :full => true
  #     ...
  #   end
  def self.deep_copy(object, options = {})
    case object
    when Numeric, TrueClass, FalseClass, NilClass, Symbol # immutable
      object
    when ::String, Yast::Path, Yast::Byteblock # immutable in sense of yast buildins
      options[:full] ? object.clone : object
    when Yast::FunRef, Yast::ArgRef, Yast::External, Yast::YReference, Yast::YCode # contains only reference somewhere
      object
    when ::Hash
      object.each_with_object({}) do |kv, acc|
        acc[deep_copy(kv[0])] = deep_copy(kv[1])
      end
    when ::Array
      object.each_with_object([]) do |v, acc|
        acc << deep_copy(v)
      end
    else
      object.clone # deep copy
    end
  end

  # Shortcut for Yast::deep_copy
  # @see Yast.deep_copy
  def deep_copy(object)
    Yast.deep_copy(object)
  end
  alias_method :copy_arg, :deep_copy

  # includes module from include directory.
  # given include must satisfied few restrictions.
  # 1) file must contain module enclosed in Yast namespace
  #    with name constructed from path and its name
  #    it is constructed that all parts is upcased
  #    and also all [-_.] is replaced and next character must be upper case.
  #    At the end is appended Include string
  #    example in file network/udev_lan.source.rb
  #    must be module Yast::NetworkUdevLanSourceInclude
  # 2) initialization of module must be in method with prefix initialize and rest is
  #    translated path, where all [-./] is replaced by underscore.
  #    Method take one parameter that is propagated target param.
  #    example in file network/udev_lan.source.rb
  #    initialization method will be initialize_network_udev_lan_source
  # @param path [String] relative path to Y2DIR/include path with file suffix
  # @param target [Class] where include module
  # @deprecated use "lib" directory where you can place common ruby code without any special handling.
  def self.include(target, path)
    path_without_suffix = path.sub(/\.rb$/, "")
    module_name = path_without_suffix
                  .gsub(/^./, &:upcase)
                  .gsub(/\/./)    { |s| s[1].upcase }
                  .gsub(/[-_.]./) { |s| s[1].upcase } +
      "Include"

    loaded = Yast.constants.include? module_name.to_sym

    unless loaded
      path = find_include_file path
      require path
    end

    mod = Yast.const_get module_name

    # if never included, then include
    target.class.send(:include, mod) unless target.class.include?(mod)

    encoded_name = path_without_suffix.gsub(/[-.\/]/, "_")
    initialized_variable = "@" + encoded_name + "initialized"
    method_name = "initialize_" + encoded_name

    # tricky condition. Here collide two yast features that had old ycp
    # 1) in clients reapeated call results in new client object, but client base class
    #    is already defined, so not needed to include again, but it's
    #    needed to be reinitialized, so we need to call initialization method
    #    even if module is already included
    # 2) if there is multi include, then only first one must call initialization
    #    because other calls are ignored
    if target.respond_to?(method_name.to_sym) &&
        !target.instance_variable_defined?(initialized_variable)
      # allways set initialized before method call otherwise endless loop in
      # circle include calls
      target.instance_variable_set(initialized_variable, true)
      target.send(method_name.to_sym, target)
    end
  end

  # imports component module with given name and create wrapper for it.
  # @note for components written in ruby just require it and it is used directly without component system.
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
        !base.const_get(modules.last).public_methods(false).empty?
      return
    end

    import_pure(mname)

    # do not create wrapper if module is in ruby and define itself object
    if base.constants.include?(modules.last.to_sym) &&
        !base.const_get(modules.last).public_methods(false).empty?
      return
    end

    m = if base.constants.include?(modules.last.to_sym)
      base.const_get(modules.last)
    else
      ::Module.new
    end
    symbols(mname).each do |sname, stype|
      next if sname.empty?
      if stype == :function
        m.define_singleton_method(sname) do |*args|
          caller(1,1).first.match BACKTRACE_REGEXP
          next Yast::call_yast_function(mname, :"#{sname}", $1, $2.to_i, *args)
        end
      elsif stype == :variable
        m.define_singleton_method(sname) do
          Yast::call_yast_function(mname, :"#{sname}")
        end
        m.define_method("#{sname}=") do |value|
          Yast::call_yast_function(mname, :"#{sname}", value)
        end
      end
    end

    base.const_set(modules.last, m) unless base.constants.include?(modules.last.to_sym)
  end
end
