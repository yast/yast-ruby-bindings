require "fast_gettext"

module YCP
  module I18n

    module ClassMethods
      def text_domain domain
        #TODO load alternative in development recent translation
        FastGettext.add_text_domain(domain, :path => "/usr/share/locale")
        FastGettext.text_domain = domain
      end
    end

    def self.included mod
      mod.extend ClassMethods
      mod.send :include, FastGettext::Translation
    end
  end
end
