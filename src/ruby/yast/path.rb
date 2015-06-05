module Yast
  # Represents paths like it is in ycp. It is path elements separated by dot.
  # Elements can be simple or complex. Simple can contain only ascii characters [a-zA-Z0-9].
  # Complex elements are enclosed by ```"``` and can contain all characters.
  # Immutable class
  class Path
    include Comparable

    def initialize(value)
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
    def +(another)
      another = self.class.from_string(another) unless another.is_a? Yast::Path
      return another.clone if components.empty?
      return clone if another.empty?
      Path.new(to_s+another.to_s)
    end

    def to_s
      '.'+components.join('.')
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
      0.upto(size-1) do |i|
        return 1 unless other.send(:components)[i]
        # we strip enclosing quotes for complex expression
        our_component = components[i].sub(/\A"(.*)"\Z/,"\\1");
        other_component = other.send(:components)[i].sub(/\A"(.*)"\Z/,"\\1");
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
    def load_components (value)
      state = :initial
      skip_next = false
      buffer = ""
      value.each_char do |c|
        case state
        when :initial
          raise "Invalid path '#{value}'" if c != '.'
          state = :dot
        when :dot
          raise "Invalid path '#{value}'" if c == '.'
          if c == '"'
            state = :complex
          else
            state = :simple
          end
          buffer << c
        when :simple
          if c == '.'
            state = :dot
            return if invalid_buffer?(buffer)

            @components << modify_buffer(buffer)
            buffer = ""
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
            buffer = ""
            next
          when '\\'
            skip_next = true
          else
            buffer << c
          end
        end
      end

      unless buffer.empty?
        return if invalid_buffer?(buffer)

        @components << modify_buffer(buffer)
      end
    end

    def invalid_buffer?(buffer)
      if buffer.start_with?("-") || buffer.end_with?("-")
        Yast.y2error "Cannot have dash before or after dot '#{value}'"
        @components.clear
        return true
      end

      false
    end

    def modify_buffer(buffer)
      if buffer =~ COMPLEX_CHAR_REGEX # we can get unescaped complex path from topath builtin
        buffer = buffer.gsub(/"/,"\\\"")
        buffer = "\"#{buffer}\""
      end

      buffer
    end
  end
end
