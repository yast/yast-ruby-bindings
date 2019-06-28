# typed: strong
module Yast::WFM
  class NoParameter; end
  YCPAny = T.type_alias(
    T.any(
      NilClass,
      T::Boolean,
      Integer,
      Float,
      Symbol,
      String,
      Array,
      Hash,
      Yast::Path,
      Yast::Term
    )
  )
  sig do
    params(
      index: T.any(Integer, NoParameter)
    ).returns(T.any(YCPAny, T::Array[YCPAny]))
  end
  def self.Args(index = NoParameter); end
end
