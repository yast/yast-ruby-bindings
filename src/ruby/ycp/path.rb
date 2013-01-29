module YCP
  class Path
    attr_reader :value

    def initialize value
      @value = value
    end

    def self.from_string string
      string = '"'+string+'"' if string =~ /[^a-zA-Z0-9_-]/
      self.new ".#{string}"
    end

    def + another
      another = self.class.from_string(another) unless another.is_a? YCP::Path
      return Path.new(self.value+another.value)
    end

    def == (second)
      return false if second.nil?
      value == second.value
    end

    def to_s
      value.to_s
    end
  end
end
