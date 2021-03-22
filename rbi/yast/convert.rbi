# typed: true

module Yast::Convert
  sig { params(object: T.untyped).returns(T.nilable(T::Boolean)) }
  def self.to_boolean(object); end

  sig { params(object: T.untyped).returns(T.nilable(Float)) }
  def self.to_float(object); end

  sig { params(object: T.untyped).returns(T.nilable(Integer)) }
  def self.to_integer(object); end

  sig { params(object: T.untyped).returns(T.nilable(Array)) }
  def self.to_list(object); end

  sig { params(object: T.untyped).returns(T.nilable(String)) }
  def self.to_locale(object); end

  sig { params(object: T.untyped).returns(T.nilable(Hash)) }
  def self.to_map(object); end

  sig { params(object: T.untyped).returns(T.nilable(Yast::Path)) }
  def self.to_path(object); end

  sig { params(object: T.untyped).returns(T.nilable(String)) }
  def self.to_string(object); end

  sig { params(object: T.untyped).returns(T.nilable(Symbol)) }
  def self.to_symbol(object); end

  sig { params(object: T.untyped).returns(T.nilable(Yast::Term)) }
  def self.to_term(object); end
end
