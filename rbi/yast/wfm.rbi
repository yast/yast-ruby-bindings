# typed: strong
module Yast::WFM
  YCPAny = T.type_alias do
    T.any(
      NilClass,
      T::Boolean,
      Integer,
      Float,
      Symbol,
      String,
      T::Array[T.untyped],
      T::Hash[T.untyped, T.untyped],
      Yast::Path,
      Yast::Term
    )
  end

  # Not an actual yast class but a helper to express
  # an optional parameter for Args which has NOT a default value.
  class NoParameter; end

  # This sig is a union of
  #  sig { params().returns(T::Array[YCPAny]) }
  #  sig { params(i: Integer).returns(YCPAny) }
  sig do
    params(
      index: T.any(Integer, NoParameter)
    ).returns(T.any(YCPAny, T::Array[YCPAny]))
  end
  def self.Args(index = NoParameter); end

  sig do
    params(
      client: String,
      args: T::Array[YCPAny]
    ).returns(YCPAny)
  end
  def self.CallFunction(client, args = []); end
end
