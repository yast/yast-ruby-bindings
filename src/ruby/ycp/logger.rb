require "ycpx"
require "ycp/builtins"

module YCP
  module_function
  def y2_logger_helper(level,args)
    caller_frame = 1
    if args.first.is_a? Fixnum
      caller_frame = caller_frame + args.shift
    end

    res = Builtins.sformat(*args)
    caller[caller_frame] =~ /(.+):(\d+):in `([^']+)'/
    y2_logger(level, "Ruby", $1, $2.to_i, "", res)
  end

  module_function
  def y2debug(*args)
    y2_logger_helper(0, args)
  end

  module_function
  def y2milestone(*args)
    y2_logger_helper(1, args)
  end

  module_function
  def y2warning(*args)
    y2_logger_helper(2, args)
  end

  module_function
  def y2error(*args)
    y2_logger_helper(3, args)
  end

  module_function
  def y2security(*args)
    y2_logger_helper(4, args)
  end

  module_function
  def y2internal(*args)
    y2_logger_helper(5, args)
  end
end # module YaST

