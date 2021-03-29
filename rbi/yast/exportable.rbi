# typed: strong

module Yast::Exportable
  sig do
    params(
      type: String,
      function: T.nilable(Symbol),
      variable: T.nilable(Symbol),
      private: T::Boolean
    ).void
  end
  def publish(type:, function: nil, variable: nil, private: false); end
end
