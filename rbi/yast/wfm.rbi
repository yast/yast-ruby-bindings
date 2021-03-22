# typed: strong
module Yast::WFM
  class NoParameter; end
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
  sig do
    params(
      index: T.any(Integer, NoParameter)
    ).returns(T.any(YCPAny, T::Array[YCPAny]))
  end
  def self.Args(index = NoParameter); end
end
