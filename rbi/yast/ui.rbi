# typed: strong

module Yast::UI
  sig do
    params(
      widget_id: T.any(Symbol, Yast::Term),
      property:  T.any(Symbol, Yast::Term),
      value:     T.untyped
    ).returns(T.untyped)
  end
  def self.ChangeWidget(widget_id, property, value); end

  sig do
    params(
      widget_id: T.any(Symbol, Yast::Term),
      property:  T.any(Symbol, Yast::Term)
    ).returns(T.untyped)
  end
  def self.QueryWidget(widget_id, property); end

  sig do
    returns(T::Boolean)
  end
  def self.TextMode; end

end
