module YCP
  class Path
    include Comparable 
    attr_reader :components

    def initialize value
      @components = []
      load_components value
    end

    def self.from_string string
      self.new ".\"#{string}\""
    end

    def clone
      Path.new(to_s())
    end

    def + another
      another = self.class.from_string(another) unless another.is_a? YCP::Path
      return another.dup if components.empty?
      return dup if another.components.empty?
      return Path.new(self.to_s+another.to_s)
    end

    def to_s
      '.'+components.join('.')
    end

    def size
      return components.size
    end

    def <=>(other)
      0.upto(components.size-1) do |i|
        return 1 unless other.components[i]
        #we strip enclosing quotes for complex expression
        our_component = components[i].sub(/\A"(.*)"\Z/,"\\1");
        other_component = other.components[i].sub(/\A"(.*)"\Z/,"\\1");
        res = our_component <=> other_component
        return res if res != 0
      end
      return size <=> other.size
    end

  private
    COMPLEX_CHAR_REGEX = /[^a-zA-Z0-9_-]/
    SIMPLE_CHAR_REGEX = /[a-zA-Z0-9_-]/
    # Rewritten ycp parser
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
            if buffer.start_with?("-") || buffer.end_with?("-")
              YCP.y2error "Cannot have dash before or after dot '#{value}'"
              @components.clear
              return
            end
            if buffer =~ COMPLEX_CHAR_REGEX # we can get unescaped complex path from topath builtin
              buffer.gsub!(/"/,"\\\"")
              buffer = "\"#{buffer}\""
            end
            @components << buffer
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
      # do not forget to pass content of remainint component
      @components << buffer unless buffer.empty?
    end
  end
end
