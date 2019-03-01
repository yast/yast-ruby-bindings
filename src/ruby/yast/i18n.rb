require "fast_gettext"
require "logger"

require "yast/translation"

module Yast
  # Provides translation wrapper.
  module I18n
    # @private
    # TODO: load alternative in development recent translation
    LOCALE_DIR = "/usr/share/YaST2/locale".freeze
    # if every heuristic fails then use the default for locale
    DEFAULT_LOCALE = "en_US".freeze

    # sets new text domain
    def textdomain(domain) # usually without brackets like textdomain "example"
      # initialize FastGettext only if the locale directory exists
      return unless File.exist? LOCALE_DIR

      # FastGettext does not track which file/class uses which text domain,
      # it has just single global text domain (the current one),
      # remember the requested text domain here
      # One object can have multiple text domains via multiple Yast.include (bnc#877687).
      @my_textdomain ||= []
      @my_textdomain << domain unless @my_textdomain.include? domain

      # initialize available locales at first use or when the current language is changed
      if FastGettext.available_locales.nil? || current_language != FastGettext.locale
        available = available_locales
        if FastGettext.available_locales != available
          # reload the translations, a new language is available
          FastGettext.translation_repositories.keys.each do |dom|
            FastGettext.add_text_domain(dom, path: LOCALE_DIR)
          end
          FastGettext.available_locales = available
        end

        FastGettext.set_locale current_language
      end

      # add the text domain (only if missing to avoid re-reading translations)
      FastGettext.add_text_domain(domain, path: LOCALE_DIR) unless FastGettext.translation_repositories[domain]
    end

    # translates given string
    # @param str [String] the string to translate
    # @return [String] the translated string, if the translation is not found then
    #   the original text is returned. **The returned String is frozen!**
    # @note **⚠ The translated string is frozen and cannot be modified. To provide
    #   consistent results the original (not translated) string is also frozen.
    #   This means this function modifies the passed argument! If you do not want this
    #   behavior then pass a duplicate, e.g. `_(text.dup)`. ⚠**
    def _(str)
      # no textdomain configured yet
      if !@my_textdomain
        Yast.y2warning("No textdomain configured, cannot translate #{str.inspect}")
        Yast.y2warning("Called from: #{::Kernel.caller(1).first}")
        return str.freeze
      end

      found = true
      # Switching textdomain clears gettext caches so avoid it if possible.
      if !@my_textdomain.include?(FastGettext.text_domain) || !key_exist?(str)
        # Set domain where key is defined.
        found = @my_textdomain.any? do |domain|
          FastGettext.text_domain = domain
          key_exist?(str)
        end
      end
      found ? Translation._(str) : str.freeze
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
    # @param [String] singular text for translators for single value
    # @param [String] plural text for translators for bigger value
    # @param [String] num the actual number, used for evaluating the correct plural form
    # @return [String] the translated string, if the translation is not found then
    #   the original text is returned (either the plural or the singular version,
    #   depending on the `num` parameter). **The returned String is frozen!**
    # @note **⚠ The translated string is frozen and cannot be modified. To provide
    #   consistent results the original (not translated) strings are also frozen.
    #   This means this function modifies the passed argument! If you do not want this
    #   behavior then pass a duplicate, e.g. `n_(singular.dup, plural.dup, n)`. ⚠**
    def n_(singular, plural, num)
      # no textdomain configured yet
      if !@my_textdomain
        # it's enough to log just the singular form
        Yast.y2warning("No textdomain configured, cannot translate text #{singular.inspect}")
        Yast.y2warning("Called from: #{::Kernel.caller(1).first}")
        return fallback_n_(singular, plural, num)
      end

      # Switching textdomain clears gettext caches so avoid it if possible.
      # difference between _ and n_ is hat we need special cache for plural forms
      found = true
      if !@my_textdomain.include?(FastGettext.text_domain) || !cached_plural_find(singular, plural)
        # Set domain where key is defined.
        found = @my_textdomain.any? do |domain|
          FastGettext.text_domain = domain
          cached_plural_find(singular, plural)
        end
      end
      found ? Translation.n_(singular, plural, num) : fallback_n_(singular, plural, num)
    end

  private

    def available_locales
      # the first item is used as the fallback
      # when the requested locale is not available
      locales = [DEFAULT_LOCALE]

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

    # Determines whether a key exist in the current textdomain
    #
    # It wraps FastGettext.key_exist? and logs Errno::ENOENT errors.
    #
    # @return [Boolean] true if it exists; false otherwise.
    # @see FastGettext.key_exist?
    def key_exist?(key)
      FastGettext.key_exist?(key)
    rescue Errno::ENOENT => error
      Yast.y2warning("File not found when translating '#{key}' on textdomain #{@my_textdomain}'. "\
        "Error: #{error}. Backtrace: #{error.backtrace}")
      false
    end

    # Determines whether a plural is cached in the current textdomain
    #
    # It wraps FastGettext.cached_plural_find and logs Errno::ENOENT errors.
    #
    # @return [Boolean] true if it exists; false otherwise.
    # @see FastGettext.cached_plural_find
    def cached_plural_find(singular, plural)
      FastGettext.cached_plural_find(singular, plural)
    rescue Errno::ENOENT => error
      Yast.y2warning("File not found when translating '#{singular}/#{plural}' "\
        "on textdomain #{@my_textdomain}'. Error: #{error}. Backtrace: #{error.backtrace}")
      false
    end

    # Returns the singular or the plural form depending on a number
    #
    # It's used as a fallback to {n_}.
    #
    # @return [String] {singular} if {num} == 1; {plural} otherwise.
    def fallback_n_(singular, plural, num)
      # always freeze both strings to have consistent results
      singular.freeze
      plural.freeze

      (num == 1) ? singular : plural
    end
  end
end

# just to make the y2makepot script happy
=begin
textdomain "example"
=end
