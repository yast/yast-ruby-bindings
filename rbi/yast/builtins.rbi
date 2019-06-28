# typed: strong

module Yast::Builtins
  sig { params(arr: Array, e: T.untyped).returns(T::Boolean) }
  def self.contains(arr, e);end

  sig do
    # params(value: T.any(String, Array, Hash, Yast::Path, Yast::Term)).returns(Integer)
    params(value: T.untyped).returns(Integer)
  end
  def self.size(value); end

  sig do
    params(format: String, args: T.untyped).void
  end
  def self.y2debug(format, *args); end

  sig do
    params(format: String, args: T.untyped).void
  end
  def self.y2error(format, *args); end

  sig do
    params(format: String, args: T.untyped).void
  end
  def self.y2milestone(format, *args); end
end
