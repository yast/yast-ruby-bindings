require "ycp/path"
require "ycp/helper"

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

    # issubstring() YCP built-in
    def self.issubstring string, substring
      return nil if string.nil? || substring.nil?
      string.include? substring
    end

    # splitstring() YCP built-in
    def self.splitstring string, sep
      return nil if string.nil? || sep.nil?
      return [] if sep.empty?

      # the big negative value forces keeping empty values in the list
      string.split /[#{Regexp.escape sep}]/, -1 * 2**20
    end

    # mergestring() YCP built-in
    def self.mergestring string, sep
      return nil if string.nil? || sep.nil?

      string.join sep
    end

    # regexpmatch() YCP built-in
    def self.regexpmatch string, regexp
      return nil if string.nil? || regexp.nil?

      # TODO FIXME: handle invalid regexps
      ruby_regexp = YCP::Helper.ruby_regexp regexp
      !string.match(ruby_regexp).nil?
    end

    # regexpsub() YCP built-in
    def self.regexpsub string, regexp, output
      return nil if string.nil? || regexp.nil? || output.nil?

      ruby_regexp = YCP::Helper.ruby_regexp regexp
      # TODO FIXME: handle invalid regexps
      if match = string.match(ruby_regexp)

        # replace the \num places
        ret = output.dup
        match.captures.each_with_index do |str, i|
          ret.gsub! "\\#{i + 1}", str
        end

        return ret
      end

      nil
    end

    # regexptokenize() YCP built-in
    def self.regexptokenize string, regexp
      return nil if string.nil? || regexp.nil?

      begin
        ruby_regexp = YCP::Helper.ruby_regexp regexp
        if match = string.match(ruby_regexp)
          return match.captures
        end
      rescue RegexpError
        # handle invalid regexps
        return nil
      end

      []
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

    # time() YCP built-in
    def self.time
      Time.now.to_i
    end

    # find() YCP built-in
    def self.find object, what
      return nil if object.nil? || what.nil?

      case object
      when String then return object.index what
      else
        raise "Invalid object for find() builtin"
      end
    end

    # contains() YCP built-in
    def self.contains list, value
      return nil if list.nil? || value.nil?
      list.include? value
    end

    # setcontains() YCP built-in
    def self.setcontains list, value
      # simply call contains(), setcontains() is just optimized contains() call
      contains list, value
    end

    # merge() YCP built-in
    def self.merge a1, a2
      return nil if a1.nil? || a2.nil?
      a1 + a2
    end

    # sort() YCP built-in
    # TODO FIXME: support also block parameter
    def self.sort array
      return nil if array.nil?

      array.sort
    end

    # toset() YCP built-in
    def self.toset array
      return nil if array.nil?
      array.uniq.sort
    end

  end
end
