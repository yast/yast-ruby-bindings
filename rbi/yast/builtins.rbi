# typed: strong

module Yast::Builtins
  sig { params(arr: T::Array[T.untyped], e: T.untyped).returns(T::Boolean) }
  def self.contains(arr, e);end

  sig do
    params(s: T.nilable(String), d_chars: String).returns(T.nilable(String))
  end
  def self.deletechars(s, d_chars); end

  sig do
    params(
      o: T.any(T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass),
      blk: T.proc.returns(T::Boolean)
    ).returns(T.any(T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass))
  end
  def self.filter(o, &blk); end

  # sig { params(o: T.nilable(String), what: String).returns(T.nilable(Integer)) }
  # sig { params(o: T.nilable(Array), blk: T.proc.returns(T::Boolean)).returns(T.nilable(Array)) }
  sig do
    params(
      o: T.any(T::Array[T.untyped], String, NilClass),
      what: String,
      blk: T.nilable(T.proc.returns(T::Boolean))
    ).returns(T.any(T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass))
  end
  def self.find(o, what = "not given", &blk); end

  sig do
    # params(value: T.any(String, Array, Hash, Yast::Path, Yast::Term)).returns(Integer)
    params(value: T.untyped).returns(Integer)
  end
  def self.size(value); end

  sig do
    params(s: T.nilable(String), d_chars: String).returns(T.nilable(T::Array[String]))
  end
  def self.splitstring(s, d_chars); end

  sig do
    params(s: T.nilable(String), offset: Integer, len: Integer).returns(T.nilable(String))
  end
  def self.substring(s, offset, len = -1); end

  sig { params(args: T.untyped).void }
  def self.y2debug(*args); end

  sig { params(args: T.untyped).void }
  def self.y2error(*args); end

  sig { params(args: T.untyped).void }
  def self.y2internal(*args); end

  sig { params(args: T.untyped).void }
  def self.y2milestone(*args); end

  sig { params(args: T.untyped).void }
  def self.y2warning(*args); end
end
