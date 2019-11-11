class RegistryEntriesController < ApplicationController
  skip_before_action :authenticate_user_account!, only: [:index, :show]

  layout "responsive"

  def create
    authorize RegistryEntry
    locale = ISO_639.find(Language.find(registry_entry_params[:lang]).code.split(/[\/-]/)[0]).alpha2
    I18n.locale = locale
    @registry_entry = RegistryEntry.create_with_parent_and_names(registry_entry_params[:parent_id], "#{locale}::#{registry_entry_params[:descriptor]}")
    @registry_entry.reload.update_attributes registry_entry_params.slice(:latitude, :longitude, :notes)
    clear_cache @registry_entry.parents.first

    respond_to do |format|
      format.json do
        render json: {
          id: @registry_entry.id,
          data_type: "registry_entries",
          data: cache_single(@registry_entry),
          reload_data_type: "registry_entries",
          reload_id: @registry_entry.parents.first.id,
        }
      end
    end
  end

  def show
    @registry_entry = RegistryEntry.find(params[:id])
    authorize @registry_entry

    respond_to do |format|
      format.json do
        render json: {
          id: @registry_entry.id,
          data_type: "registry_entries",
          data: cache_single(@registry_entry),
        }
      end
    end
  end

  # TODO: test for multiple languages
  def update
    @registry_entry = RegistryEntry.find params[:id]
    authorize @registry_entry
    I18n.locale = ISO_639.find(Language.find(registry_entry_params[:lang]).code.split(/[\/-]/)[0]).alpha2
    @registry_entry.update_attributes registry_entry_params.slice(:descriptor, :notes, :latitude, :longitude, :parent_id)
    @registry_entry.touch
    @registry_entry.parents.each(&:touch)

    respond_to do |format|
      format.json do
        render json: {
          id: @registry_entry.id,
          data_type: "registry_entries",
          data: cache_single(@registry_entry),
        }
      end
    end
  end

  def index
    policy_scope RegistryEntry

    respond_to do |format|
      format.html { render "react/app" }
      format.json do
        registry_entries, extra_params =
          if params[:children_for_entry]
            [
              RegistryEntry.find(params[:children_for_entry]).children,
              "children_for_entry_#{params[:children_for_entry]}",
            ]
          elsif params[:references_for_segment]
            [
              Segment.find(params[:references_for_segment]).registry_entries,
              "references_for_segment_#{params[:references_for_segment]}",
            ]
          elsif params[:references_for_interview]
            [
              Interview.find_by_archive_id(params[:references_for_interview]).registry_entries.where("registry_references.registry_reference_type_id": params[:type_id]),
              "references_for_interview_#{params[:references_for_interview]}_type_id_#{params[:type_id]}",
            ]
          elsif params[:references_for_person]
            [
              Person.find(params[:references_for_person]).registry_entries.where("registry_references.registry_reference_type_id": params[:type_id]),
              "references_for_person_#{params[:references_for_person]}_type_id_#{params[:type_id]}",
            ]
          end

        json = Rails.cache.fetch "#{current_project.cache_key_prefix}-#{extra_params}-#{RegistryEntry.maximum(:updated_at)}" do
          registry_entries = registry_entries.includes(registry_names: :translations)
          {
            data: registry_entries.inject({}) { |mem, s| mem[s.id] = cache_single(s); mem },
            data_type: "registry_entries",
            extra_params: extra_params,
          }
        end.to_json
        render plain: json
      end
      format.pdf do
        @registry_entries = RegistryEntry.where(code: current_project.pdf_registry_entry_codes).map { |e| e.descendants.includes(registry_names: :translations) }.flatten.sort { |a, b| a.descriptor <=> b.descriptor }
        @locale = params[:locale]
        pdf = render_to_string(:template => "/registry_entries/index.pdf.erb", :layout => "latex.pdf.erbtex")
        send_data pdf, filename: "registry_entries_#{@locale}.pdf", :type => "application/pdf" #, :disposition => "attachment"
      end
    end
  end

  def merge
    @registry_entry = RegistryEntry.find(params[:id])
    authorize @registry_entry
    #policy_scope RegistryEntry
    RegistryEntry.merge({id: params[:id], ids: params[:merge_registry_entry][:ids]})

    respond_to do |format|
      format.json do
        render json: {
            data_type: 'registry_entries',
            msg: 'processing'
          }, status: :ok
      end
    end
  end

  def destroy
    @registry_entry = RegistryEntry.find(params[:id])
    authorize @registry_entry

    parent = @registry_entry.parents.first
    @registry_entry.destroy

    clear_cache parent
    parent.touch
    parent.reload

    respond_to do |format|
      format.html do
        render :action => "index"
      end
      format.json do
        render json: {
          id: parent.id,
          data_type: "registry_entries",
          data: Rails.cache.fetch("#{current_project.cache_key_prefix}-registry_entry-#{parent.id}-#{parent.updated_at}") { ::RegistryEntrySerializer.new(parent).as_json },
        }, status: :ok
      end
    end
  end

  private

  def registry_entry_params
    params.require(:registry_entry).permit(:workflow_state, :parent_id, :registry_name_type_id, :name_position, :descriptor, :notes, :latitude, :longitude, :lang)
  end
end
