require 'globalize'

class RegistryReferenceType < ActiveRecord::Base

  translates :name, fallbacks_for_empty_translations: true, touch: true

  # The relation to a registry entry defines "allowed" registry
  # reference types for all registry entries that are descendants
  # of the entry pointed to here.
  belongs_to :registry_entry

  # The relation to registry references defines "assigned"
  # reference types for registry references. These are reference
  # types actually in use to define the type of a reference.
  has_many :registry_references, :dependent => :nullify

  def to_s(locale = I18n.locale)
    name(locale)
  end

  def to_sym
    code.to_sym
  end

  def to_hash
    {
        :id => id,
        :name => name
    }
  end

  def localized_hash
    translations.inject({}) do |mem, t|
      mem[t.locale[0..1]] = t.name  if I18n.available_locales.include?( t.locale[0..1] ) || I18n.available_locales.include?( t.locale )
      mem
    end
  end
  
end
