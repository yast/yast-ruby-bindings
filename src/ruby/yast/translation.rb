# typed: strong
require "fast_gettext"

module Yast
  # Just a wrapper around FastGettext::Translation, we cannot include it
  # directly because we define our own _() and n_() methods.
  module Translation
    extend FastGettext::Translation
  end
end
