require 'globalize'

class Language < ActiveRecord::Base

  RTL_LANGUAGES = %w( Hebräisch Arabisch )

  translates :name, :abbreviated, fallbacks_for_empty_translations: true, touch: true
  accepts_nested_attributes_for :translations

  has_many :interviews

  after_update :touch_interviews

  class << self
    def find_by_name(name)
      Language.joins(:translations).includes(:translations).
          where('language_translations.locale = ? AND language_translations.name = ?', 'de', name).first
    end

    def german
      find_by_name 'Deutsch'
    end

    def english
      find_by_name 'Englisch'
    end

    def options
      Language.all.includes(:translations).sort_by(&:name)
    end
  end

  def first_code
    code.split(/[\/-]/)[0]
  end

  def to_s(locale = I18n.locale)
    name(locale)
  end

  def localized_hash
    I18n.available_locales.inject({}) do |mem, locale|
      mem[locale] = name(locale) 
      mem
    end
  end

  def direction
    @direction ||= RTL_LANGUAGES.include?(name) ? 'RTL' : 'LTR'
  end

  private

  def touch_interviews
    interviews.update_all(updated_at: DateTime.now)
  end

end
