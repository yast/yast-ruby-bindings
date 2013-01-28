module YCP
  class Path
    attr_reader :value

    def initialize value
      @value = value
    end

    def self.load_from_string string
      string = '"'+string+'"' if string =~ /[^a-zA-Z0-9_-]/
      self.new ".#{string}"
    end

    def + another
      another = self.class.load_from_string(another) unless another.is_a? YCP::Path
      return Path.new(self.value+another.value)
    end

    def == (second)
      value == second.value
    end

    def != (second)
      !(self == second)
    end
  end
end
