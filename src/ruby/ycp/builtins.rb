require "ycp/path"

module YCP
  module Builtins
    # Method that simulates behavior of add in ycp builtin.
    # Most notably difference is that it always create new object
    # For new code it is recommended to use directly methods on objects
    def self.add object, *params
      case object
      when Array then return object + params
      when Hash then  return object.merge(Hash[*params])
      #TODO when YCP::Term:
      when YCP::Path then return object + params.first
      else
        raise "Invalid object for add builtin"
      end
    end
  end
end
