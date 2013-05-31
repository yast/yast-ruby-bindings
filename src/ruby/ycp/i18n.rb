require "fast_gettext"

module YCP
  module I18n

    #TODO load alternative in development recent translation
    LOCALE_DIR = "/usr/share/YaST2/locale"
    DEFAULT_LOCALE = "en_US"

    def textdomain domain
      # TODO FIXME:
      # A single combined text domain is used for all translations
      # to solve the problem with switching domain across different files
      #
      # FastGettext does not track which file/class uses which text domain,
      # it has just single global text domain (the current one)
      #
      # This simple code does not work properly:
      #        FastGettext.add_text_domain(domain, :path => LOCALE_DIR)
      #        FastGettext.text_domain = domain

      # initialize available locales at first use or when the current language is changed
      if FastGettext.available_locales.nil? || current_language != FastGettext.locale

        # see https://github.com/grosser/fast_gettext#chains about the FastGettext chains
        FastGettext.add_text_domain "combined", :type => :chain, :chain => combined_repositories
        FastGettext.default_text_domain = "combined"

        FastGettext.available_locales = available_locales
        FastGettext.set_locale current_language
      end
    end

    private

    # get translation repositories for all available text domains
    def combined_repositories
      text_domains = []
      repos = []

      Dir[File.join(LOCALE_DIR, "*/LC_MESSAGES/*.mo")].each do |mofile|
        text_domain = File.basename(mofile, ".mo")

        if !text_domains.include? text_domains
          repos << FastGettext::TranslationRepository.build(text_domain, :path => LOCALE_DIR)
          text_domains << text_domain
        end
      end

      repos
    end

    def available_locales
      # the first item is used as the fallback
      # when the requested locale is not available
      locales = [ DEFAULT_LOCALE ]

      Dir["#{LOCALE_DIR}/*"].each do |f|
        locale_name = File.basename f
        locales << locale_name if File.directory?(f) && !locales.include?(locale_name)
      end

      locales
    end

    def current_language
      # get the current value from YaST (remove the trailing encoding
      # like ".UTF-8" if present)
      lang = WFM.GetLanguage.gsub(/\..*$/, "")

      return DEFAULT_LOCALE if lang.empty?

      # remove the country suffix if that locale is not available
      # e.g. there are "pt_BR" and "de" translations (there is generic "pt" but no "de_DE")
      lang.gsub!(/_.*$/, "") if FastGettext.available_locales.nil? || !FastGettext.available_locales.include?(lang)

      lang
    end

    def self.included mod
      mod.send :include, FastGettext::Translation
    end
  end
end
