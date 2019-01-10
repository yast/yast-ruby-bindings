require "yast"

module Yast
  # For passing exceptions through liby2
  class Y2ExceptionClass < Module
    def main
      @exception = {}
    end

    publish variable: :exception, type: "map"
  end

  Y2Exception = Y2ExceptionClass.new
  Y2Exception.main
end
