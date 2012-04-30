module InRuby
  def self.multiply_by_eight(n)
    n * 8
  end

  def self.raising_code
    raise "Wow exception!"
  end

  def self.get_hash
    return { "a" => "b", "b" => "c" }
  end
end
