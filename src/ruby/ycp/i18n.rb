require "fast_gettext"

module YCP
  module I18n

    #TODO load alternative in development recent translation
    LOCALE_DIR = "/usr/share/YaST2/locale"
    DEFAULT_LOCALE = "en_US"

    def textdomain domain
      # FastGettext does not track which file/class uses which text domain,
      # it has just single global text domain (the current one),
      # remember the requested text domain here
      @my_textdomain = domain

      # initialize available locales at first use or when the current language is changed
      if FastGettext.available_locales.nil? || current_language != FastGettext.locale
        available = available_locales
        if FastGettext.available_locales != available
          # reload the translations, a new language is available
          FastGettext.translation_repositories.keys.each {|dom| FastGettext.add_text_domain(domain, :path => LOCALE_DIR)}
          FastGettext.available_locales = available
        end

        FastGettext.set_locale current_language
      end

      # add the text domain (only if missing to avoid re-reading translations)
      FastGettext.add_text_domain(domain, :path => LOCALE_DIR) unless FastGettext::translation_repositories[domain]
    end

    def _(str)
      old_text_domain = FastGettext.text_domain
      FastGettext.text_domain = @my_textdomain
      FastGettext::Translation::_ str
    ensure
      FastGettext.text_domain = old_text_domain
    end

    def n_(singular, plural, num)
      old_text_domain = FastGettext.text_domain
      FastGettext.text_domain = @my_textdomain
      FastGettext::Translation::n_(singular, plural, num)
    ensure
      FastGettext.text_domain = old_text_domain
    end

    private

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

  end
end
