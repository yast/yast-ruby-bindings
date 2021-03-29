# typed: strong

module Yast::Ops
  sig { params(a: T.nilable(Object), b: T.nilable(Object)).returns(T.nilable(Object)) }
  def self.add(a, b); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_boolean(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_float(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_integer(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_list(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_locale(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_map(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_path(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_string(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_symbol(object, indexes, default=T.unsafe(nil), &block); end

  sig do
    params(
      object: T.untyped,
      indexes: T.untyped,
      default: T.untyped,
      block: T.nilable(T.proc.returns(T.untyped))
    ).returns(T.untyped)
  end
  def self.get_term(object, indexes, default=T.unsafe(nil), &block); end

  sig { params(a: T.nilable(Object), b: T.nilable(Object)).returns(T.nilable(T::Boolean)) }
  def self.greater_than(a, b); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_any?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_boolean?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_byteblock?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_float?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_function?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_integer?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_list?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_locale?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_map?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_nil?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_path?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_string?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_symbol?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_term?(object); end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def self.is_void?(object); end

  sig { params(a: T.nilable(Object), b: T.nilable(Object)).returns(T.nilable(T::Boolean)) }
  def self.less_than(a, b); end
end
