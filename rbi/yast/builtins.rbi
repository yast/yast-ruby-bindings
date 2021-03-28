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
  # sig { params(o: T.nilable(Array), blk: T.proc.returns(T::Boolean)).returns(T.untyped) }
  sig do
    params(
      # the FalseClass is nonsense to fool the exhaustiveness checker
      object: T.any(T::Array[T.untyped], String, NilClass, FalseClass),
      what: T.nilable(String),
      block: T.nilable(T.proc.params(e: T.untyped).returns(T::Boolean))
    ).returns(T.untyped)
  end
  def self.find(object, what = nil, &block); end

  sig do
    params(
      # YCP will just warn if it's not an Array or Hash
      object: T.nilable(T.any(T::Array[T.untyped], T::Hash[T.untyped, T.untyped])),
      # See "foreach block voodoo" below
      #   block: T.any(
      #     T.proc.params(elem: T.untyped).returns(T.untyped),
      #     T.proc.params(key: T.untyped, value: T.untyped).returns(T.untyped)
      #   )
    ).void
  end
  def self.foreach(object, &block); end

  # ^^^
  # foreach block voodoo:
  #
  # Short: Sorbet bug. We'd like to specify the block type as commented, but
  # if we do, downstream yast code will fail with "This code is unreachable,
  # This expression always raises or can never be computed". Fortunately
  # omitting the block param entirely falls back to block arguments getting
  # T.untyped which is just what we want.
  #
  # Long:
  #
  # If we set the block type to the commented out any(one_param, two_params)
  # then apparently it exposes a bug in sorbet which thinks the block should
  # take zero arguments (and thus would raise at runtime when seeing one):
  #
  #   $ srb t -e 'Yast::Builtins.foreach([1,2,3,4,5,6]) { |i| puts i }'
  #   -e:1: This code is unreachable https://srb.help/7006
  #        1 |Yast::Builtins.foreach([1,2,3,4,5,6]) { |i| puts i }
  #                                                    ^
  #   $ srb t -e 'Yast::Builtins.foreach([1,2,3,4,5,6]) { puts 6 }'
  #   No errors! Great job.
  #
  # With the declaration commented out, the correct one-param code passes.
  # Unfortunately, incorrect no-param block or even no block at all passes too.
  # That's an acceptable loophole until we get sorbet fixed.
  #
  # I have also tried these unsuccessfully:
  #
  # - `block: Proc` restricts the block arguments to BasicObject.
  # - `block: T.proc` works on https://sorbet.run but fails with
  #    'Malformed T.proc: You must specify a return type' in a current version.
  # - `block: T.proc.returns(T.untyped)` restricts the arguments to NilClass.
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

  sig { params(object: T.untyped).returns(T.nilable(Integer)) }
  def self.tointeger(object); end

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
