# typed: strong

# Namespacing note:
# if we say `module Yast::I18n` then String means ::String
# if we said `module Yast; module I18n` then String would mean Yast::String

module Yast::I18n
  sig { params(domain: String).void }
  def textdomain(domain); end

  sig { params(str: String).returns(String) }
  def _(str); end
  sig { params(str: String).returns(String) }
  def N_(str); end
end
