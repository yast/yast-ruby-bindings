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

    # substring() YCP built-in
    # little bit complicated because YCP returns different values
    # in corner cases (nil or negative parameters, out of range...)
    def self.substring string, offset, length = -1
      return nil if string.nil? || offset.nil? || length.nil?
      return "" if offset < 0 || offset >= string.size

      length = string.size - offset if length < 0

      string[offset, length]
    end

    # tolower() YCP built-in
    def self.tolower string
      return nil if string.nil?
      string.downcase
    end

    # toupper() YCP built-in
    def self.toupper string
      return nil if string.nil?
      string.upcase
    end

    # size() YCP built-in
    def self.size object
      return nil if object.nil?

      case object
      when String, Array, Hash, YCP::Term then return object.size
      else
        raise "Invalid object for size() builtin"
      end
    end
  end
end
