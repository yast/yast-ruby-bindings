require "fast_gettext"

module Yast
  # Provides translation wrapper.
  module I18n

    # @private
    #TODO load alternative in development recent translation
    LOCALE_DIR = "/usr/share/YaST2/locale"
    # if every heuristic fails then use the default for locale
    DEFAULT_LOCALE = "en_US"

    # sets new text domain
    def textdomain domain
      # initialize FastGettext only if the locale directory exists
      return unless File.exist? LOCALE_DIR

      # FastGettext does not track which file/class uses which text domain,
      # it has just single global text domain (the current one),
      # remember the requested text domain here
      @my_textdomain = domain

      # initialize available locales at first use or when the current language is changed
      if FastGettext.available_locales.nil? || current_language != FastGettext.locale
        available = available_locales
        if FastGettext.available_locales != available
          # reload the translations, a new language is available
          FastGettext.translation_repositories.keys.each {|dom| FastGettext.add_text_domain(dom, :path => LOCALE_DIR)}
          FastGettext.available_locales = available
        end

        FastGettext.set_locale current_language
      end

      # add the text domain (only if missing to avoid re-reading translations)
      FastGettext.add_text_domain(domain, :path => LOCALE_DIR) unless FastGettext::translation_repositories[domain]
    end

    # translates given string
    def _(str)
      # no textdomain configured yet
      return str unless @my_textdomain

      old_text_domain = FastGettext.text_domain
      FastGettext.text_domain = @my_textdomain
      FastGettext::Translation::_ str
    ensure
      FastGettext.text_domain = old_text_domain
    end

    # No translation, only marks the text to be found by gettext when creating POT file,
    # the text needs to be translated by {#_} later.
    #
    # @example Error messages
    #  begin
    #    # does not translate, the exception contains the untranslated string,
    #    # but it's recognized by gettext like normal _()
    #    raise FooError, N_("Foo failed.")
    #  rescue FooError => e
    #    # log the original (untranslated) error
    #    log.error e.message
    #
    #    # but display translated error to the user,
    #    # _() does the actual translation
    #    Popup.Error(_(e.message))
    #  end
    #
    # @example Translating Constants
    #  class Foo
    #    # ERROR_MSG will not be translated, but the string will be found
    #    # by gettext when creating the POT file
    #    ERROR_MSG = N_("Something failed")
    #  end
    #
    #  # here the string will be translated using the current locale
    #  puts _(Foo::ERROR_MSG)
    #
    def N_(str)
      str
    end

    # No translation, only marks the texts to be found by gettext when creating POT file,
    # the texts need to be translated by {#n_} later.
    def Nn_(*keys)
      keys
    end

    # Gets translation based on number.
    # @param (String) singular text for translators for single value
    # @param (String) plural text for translators for bigger value
    def n_(singular, plural, num)
      # no textdomain configured yet
      return (num == 1) ? singular : plural unless @my_textdomain

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
