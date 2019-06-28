# typed: strong

module Yast
  sig { params(p: T.any(Yast::Path, ::String)).returns(Yast::Path)}
  def self.path(p); end

  sig { params(p: T.any(Yast::Path, ::String)).returns(Yast::Path)}
  def path(p); end
end
