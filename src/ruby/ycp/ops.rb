module Ops
  def self.equal first, second
    return first == second
  end

  def self.not_equal first, second
    return !equal(first, second)
  end
end
