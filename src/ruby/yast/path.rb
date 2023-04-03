# frozen_string_literal: true
module Yast
  # Represents paths like it is in ycp. It is path elements separated by dot.
  # Elements can be simple or complex. Simple can contain only ascii characters [a-zA-Z0-9].
  # Complex elements are enclosed by ```"``` and can contain all characters.
  # Immutable class
  class Path
    include Comparable

    # @param value [String] string representation of path
    # @raise RuntimeError if invalid path is passed. Invalid path is one where
    # any element starts or ends with dash like ".-etc", ".etc-" or ".e.t-.c"
    def initialize(value)
      if !value.is_a?(::String)
        raise ArgumentError, "Yast::Path constructor has to get ::String as " \
          "argument instead of '#{value.inspect}'"
      end
      @components = []
      load_components value
    end

    # Creates path from generic string
    def self.from_string(string)
      new ".\"#{string}\""
    end

    def clone
      self
    end

    # concats path
    def +(other)
      other = self.class.from_string(other) unless other.is_a? Yast::Path
      return other.clone if components.empty?
      return clone if other.empty?
      Path.new(to_s + other.to_s)
    end

    def to_s
      "." + components.join(".")
    end

    # gets number of elements
    def size
      components.size
    end

    # Detect if there is no  elements
    def empty?
      components.empty?
    end

    def <=>(other)
      return nil unless other.is_a? self.class
      0.upto(size - 1) do |i|
        return 1 unless other.send(:components)[i]
        # we strip enclosing quotes for complex expression
        our_component = components[i].sub(/\A"(.*)"\Z/, "\\1")
        other_component = other.send(:components)[i].sub(/\A"(.*)"\Z/, "\\1")
        res = our_component <=> other_component
        return res if res != 0
      end
      size <=> other.size
    end

  private

    attr_reader :components
    COMPLEX_CHAR_REGEX = /[^a-zA-Z0-9_-]/
    SIMPLE_CHAR_REGEX = /[a-zA-Z0-9_-]/
    # Rewritten yast parser
    def load_components(value)
      state = :initial
      skip_next = false
      buffer = "".dup
      value.each_char do |c|
        case state
        when :initial
          raise "Invalid path '#{value}'" if c != "."
          state = :dot
        when :dot
          raise "Invalid path '#{value}'" if c == "."
          state = if c == '"'
            :complex
          else
            :simple
          end
          buffer << c
        when :simple
          if c == "."
            state = :dot
            raise "Invalid path '#{value}'" if invalid_buffer?(buffer)

            @components << modify_buffer(buffer)
            buffer = "".dup
            next
          end
          buffer << c
        when :complex
          if skip_next
            buffer << c
            skip_next = false
            next
          end

          case c
          when '"'
            state = :initial
            buffer << c
            @components << buffer
            buffer = "".dup
            next
          when '\\'
            skip_next = true
          else
            buffer << c
          end
        end
      end

      return if buffer.empty?

      raise "Invalid path '#{value}'" if invalid_buffer?(buffer)

      @components << modify_buffer(buffer)
    end

    def invalid_buffer?(buffer)
      if buffer.start_with?("-") || buffer.end_with?("-")
        return true
      end

      false
    end

    def modify_buffer(buffer)
      if buffer =~ COMPLEX_CHAR_REGEX # we can get unescaped complex path from topath builtin
        buffer = buffer.gsub(/"/, "\\\"")
        buffer = "\"#{buffer}\""
      end

      buffer
    end
  end
end
