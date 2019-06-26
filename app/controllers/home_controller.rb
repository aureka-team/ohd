class HomeController < ApplicationController

  layout 'responsive'

  skip_before_action :authenticate_user_account!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def map_tutorial
    render layout: false
  end

  def archive
    respond_to do |format|
      format.html do
        render :template => '/react/app.html'
      end
      format.json do
        locales = Project.available_locales.reject{|i| i == 'alias'}
        json = Rails.cache.fetch("#{Project.cache_key_prefix}-static-content") do 
          {
            external_links: Project.external_links,
            translations: translations,
            country_keys: locales.inject({}) do |mem, locale|
              mem[locale] = ISO3166::Country.translations(locale).sort_by{|key, value| value}.to_h.keys
              mem
            end,
            collections: Collection.all.map{|c| {value: c.id, name: c.localized_hash}}, 
            contribution_types: Project.contribution_types,
            registry_entry_search_facets: Project.registry_entry_search_facets.map{|facet| {id: RegistryEntry.find_by_entry_code(facet['id']).id, display_on_landing_page: facet['display_on_landing_page']}},
            person_properties_registry_reference_type: Project.person_properties_registry_reference_type.inject({}){|mem, facet| mem[facet['id']] = RegistryReferenceTypeSerializer.new(RegistryReferenceType.find_by_code(facet['id'])).as_json; mem},
            languages: Language.all.map{|c| {value: c.id.to_s, name: c.localized_hash, locale: ISO_639.find(c.code.split(/[\/-]/)[0]).alpha2}}, 
            upload_types: Project.upload_types,
            project: Project.name.to_s,
            project_name: Project.project_name,
            project_domain: Project.project_domain,
            project_doi: Project.project_doi,
            archive_domain: Project.archive_domain,
            locales: Project.available_locales,
            view_modes: Project.view_modes,
            view_mode: Project.view_modes[0],
            list_columns: Project.list_columns,
            media_streams: Project.media_streams,
            hidden_registry_entry_ids: Project.hidden_registry_entry_ids,
          }
        end
        home_content = {}
        locales.each do |i|
          I18n.locale = i
          template = "/home/home.#{i}.html+#{Project.name == 'empty' ? 'zwar' : Project.name}"
          home_content[i] = render_to_string(template: template, layout: false)
        end
        json[:home_content] = home_content
        render plain: json.to_json
      end
    end
  end

  def faq_archive_contents
  end

  def faq_index
  end

  def faq_searching
  end

  def faq_technical
  end

  def map_tutorial
  end

  private

  def translations
    I18n.available_locales.inject({}) do |mem, locale|
      mem[locale] = instance_variable_get("@#{locale}") || 
        instance_variable_set("@#{locale}", 
                              YAML.load_file(File.join(Rails.root, "config/locales/#{locale}.yml"))[locale.to_s].deep_merge(
                                YAML.load_file(File.join(Rails.root, "config/locales/devise.#{locale}.yml"))[locale.to_s]).merge(
                                  countries: ISO3166::Country.translations(locale)
                                )
                             )
      mem
    end
  end

end
