
module YCP
  module Helper

    # helper for transforming YCP regexps to Ruby regexps
    # replace YCP regexp metacharacters by Ruby ones
    # ^ -> \A, $ -> \z
    def self.ruby_regexp reg_str
      return nil if reg_str.nil?

      reg_str.gsub(/\A\^/, '\\A').gsub(/\$\z/, '\\z')
    end

  end
end