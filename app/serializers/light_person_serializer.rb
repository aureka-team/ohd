class LightPersonSerializer < ApplicationSerializer
  attributes :id, :names, :name

  def names
      object.translations.each_with_object({}) {|i, hsh |
        alpha2_locale = ISO_639.find(i.locale.to_s).alpha2
        hsh[alpha2_locale] = {firstname: i.first_name,
                         lastname: i.last_name,
                         birthname: i.birth_name} if I18n.available_locales.include?( alpha2_locale )}
  end

end
