class InterviewsController < ApplicationController
  include IsoHelpers
  layout 'responsive'

  skip_before_action :authenticate_user_account!, only: [:show, :doi_contents]
  skip_after_action :verify_authorized, only: [:show, :doi_contents, :metadata]
  skip_after_action :verify_policy_scoped, only: [:show, :doi_contents, :metadata]

  def new
    authorize Interview
    respond_to do |format|
      format.html { render :show }
      format.json { render json: :ok }
    end
  end

  def create
    authorize Interview
    @interview = Interview.create interview_params
    @interview.send("#{params[:interview][:workflow_state]}!") if params[:interview][:workflow_state]

    respond_to do |format|
      format.json do
        render json: data_json(@interview, msg: 'processed')
      end
    end
  end

  def edit
    authorize Interview
    respond_to do |format|
      format.html { render :show }
    end
  end

  def update
    @interview = Interview.find_by_archive_id params[:id]
    authorize @interview
    @interview.update_attributes interview_params

    clear_cache @interview

    respond_to do |format|
      format.json do
        render json: data_json(@interview, msg: 'processed')
      end
    end
  end

  def mark_texts
    @interview = Interview.find_by_archive_id params[:id]
    authorize @interview
    texts_to_mark = mark_text_params[:texts] && JSON.parse(mark_text_params[:texts]).map{|t| t['text_to_mark']}
    
    MarkTextJob.perform_later(@interview, texts_to_mark, mark_text_params[:locale], current_user_account)

    respond_to do |format|
      format.json do
        render json: {
          msg: "processing",
          id: @interview.archive_id,
          data_type: 'interviews',
          nested_data_type: 'texts_to_mark'
        }, status: :ok
      end
    end
  end

  def update_speakers
    @interview = Interview.find_by_archive_id params[:id]
    authorize @interview
    contribution_data = update_speakers_params[:contributions] && JSON.parse(update_speakers_params[:contributions])
    
    # speakers are people designated through column speaker in segment.
    # contributors (contribution_data) are people designated through column speaker_id
    #
    AssignSpeakersJob.perform_later(@interview, speakers, contribution_data, current_user_account)

    respond_to do |format|
      format.json do
        render json: {
          msg: "processing",
          id: @interview.archive_id,
          data_type: 'interviews',
          nested_data_type: 'speaker_designations'
        }, status: :ok
      end
    end
  end

  def speaker_designations
    @interview = Interview.find_by_archive_id(params[:id])
    authorize @interview

    respond_to do |format|
      format.json do
        json = Rails.cache.fetch "#{Project.cache_key_prefix}-interview-speaker_designations-#{@interview.id}-#{@interview.segments.maximum(:updated_at)}" do
          {
            data: @interview.speaker_designations,
            nested_data_type: 'speaker_designations',
            data_type: 'interviews',
            archive_id: params[:id],
            msg: @interview.speaker_designations.empty? ? 'second_step_explanation' : 'first_step_explanation'
          }
        end.to_json
        render plain: json
      end
    end
  end

  def show
    @interview = Interview.find_by_archive_id(params[:id])
    @locale = projectified(params[:locale])
    interview_locale = ISO_639.find(@interview.language.code).send(Project.alpha)

    respond_to do |format|
      format.json do
        render json: data_json(@interview)
      end
      format.vtt do
        vtt = Rails.cache.fetch "#{Project.cache_key_prefix}-interview-vtt-#{@interview.id}-#{@interview.updated_at}-#{params[:lang]}-#{params[:tape_number]}" do
          @interview.to_vtt(params[:lang] || interview_locale, params[:tape_number])
        end
        render plain: vtt
      end
      format.pdf do
        @lang = params[:lang].to_sym
        @orig_lang = projectified(@interview.language.code)
        pdf =   render_to_string(:template => '/latex/interview_transcript.pdf.erb', :layout => 'latex.pdf.erbtex')
        send_data pdf, filename: "#{@interview.archive_id}_transcript_#{@lang}.pdf", :type => "application/pdf"#, :disposition => "attachment"
      end
      format.ods do
        send_data @interview.to_ods(interview_locale, params[:tape_number]), filename: "#{@interview.archive_id}_transcript_#{locale}_tc_tab.ods", type: "application/vnd.oasis.opendocument.spreadsheet"#, :disposition => "attachment"
      end
      format.html
    end
  end

  def destroy 
    @interview = Interview.find_by_archive_id(params[:id])
    authorize @interview
    @interview.destroy

    clear_cache @interview

    respond_to do |format|
      format.html do
        render action: 'index'
      end
      format.json do 
        json = {
          archive_id: params[:id],
          data_type: 'interviews',
          msg: 'deleted'
        }
        render json: json, status: :ok
      end
    end
  end

  def metadata
    @interview = Interview.find_by_archive_id(params[:id])
    @locale = projectified(params[:locale])
    respond_to do |format|
      format.xml
    end
  end

  def dois
    results = {}

    # curl -X POST -H "Content-Type: application/vnd.api+json" --user YOUR_CLIENT_ID:YOUR_PASSWORD -d @my_draft_doi.json https://api.test.datacite.org/dois
    uri = URI.parse(Rails.configuration.datacite['url'])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    params[:archive_ids].each do |archive_id|
      interview = Interview.find_by_archive_id(archive_id)
      authorize interview

      unless interview.doi_status == 'created'
        request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/vnd.api+json'})
        request.basic_auth(Rails.configuration.datacite['client_id'], Rails.configuration.datacite['password'])
        request.body = doi_json(archive_id)

        response = http.request(request)

        status = response.code == '201' ? 'created' : JSON.parse(response.body)['errors'][0]['title']
        interview.update_attributes doi_status: status
      else
        status = 'created'
      end

      results[archive_id] = status
    end

    respond_to do |format|
      format.json do
        render json: results
      end
    end
  end

  def doi_contents
    json = {}
    unless params[:id] == 'new'
      @interview = Interview.find_by_archive_id(params[:id])
      json = Rails.cache.fetch "#{Project.cache_key_prefix}-interview-doi-contents-#{@interview.archive_id}-#{@interview.updated_at}" do
        locales = Project.available_locales.reject{|locale| locale == 'alias'}
        doi_contents = locales.inject({}){|mem, locale| mem[locale] = doi_content(locale, @interview); mem}
        {
          archive_id: params[:id],
          data_type: 'interviews',
          nested_data_type: 'doi_contents',
          data: doi_contents,
        }
      end
    end

    respond_to do |format|
      format.json do
        render json: json, status: :ok
      end
    end
  end

  def headings
    @interview = Interview.find_by_archive_id(params[:id])
    authorize @interview
    respond_to do |format|
      format.json do
        json = Rails.cache.fetch "#{Project.cache_key_prefix}-interview-headings-#{@interview.id}-#{@interview.segments.maximum(:updated_at)}" do
          segments = @interview.segments.
              includes(:translations, :annotations => [:translations]).#, registry_references: {registry_entry: {registry_names: :translations}, registry_reference_type: {} } ).
              where.not(timecode: '00:00:00.000')
          {
            data: segments.with_heading.map {|s| Rails.cache.fetch("#{Project.cache_key_prefix}-headings-#{s.id}-#{s.updated_at}"){::HeadingSerializer.new(s).as_json}},
            nested_data_type: 'headings',
            data_type: 'interviews',
            archive_id: params[:id]
          }
        end.to_json
        render plain: json
      end
    end
  end

  def ref_tree
    @interview = Interview.find_by_archive_id(params[:id])
    authorize @interview
    respond_to do |format|
      format.json do
        json = Rails.cache.fetch "#{Project.cache_key_prefix}-interview-ref-tree-#{@interview.id}-#{RegistryEntry.maximum(:updated_at)}" do
          ref_tree = ReferenceTree.new(@interview.segment_registry_references)
          {
            data: ActiveRecord::Base.connection.column_exists?(:registry_entries, :entry_dedalo_code) ? ref_tree.part(RegistryEntry.where(entry_dedalo_code: "ts1_1").first.id) : ref_tree.part(1),
            nested_data_type: 'ref_tree',
            data_type: 'interviews',
            archive_id: params[:id]
          }
        end.to_json
        render plain: json
      end
    end
  end

  private

  def interview_params
    params.require(:interview).
      permit(
        'collection_id',
        'archive_id',
        'language_id',
        'interview_date',
        'video',
        'translated',
        'observations',
        'workflow_state'
    )
  end

  def mark_text_params
    params.require(:mark_text).
      permit(
        'texts',
        'locale'
    )
  end

  def update_speakers_params
    params.require(:update_speaker).
      permit(
        'contributions',
        speakers: {}
    )
  end

  def speakers
    update_speakers_params[:speakers].to_h
  end

  def doi_json(archive_id)
    @interview = Interview.find_by_archive_id(archive_id)
    @locale = projectified(params[:locale])
    xml = render_to_string(template: "/interviews/metadata.xml", layout: false)
    {
      "data": {
        "id": "#{Rails.configuration.datacite['prefix']}/#{Project.name}.#{archive_id}",
        "type": "dois",
        "attributes": {
          "doi": "#{Rails.configuration.datacite['prefix']}/#{Project.name}.#{archive_id}",
          "event": "publish",
          "url": "https://www.datacite.org",
          "xml": Base64.encode64(xml)
        }
      }
    }.to_json
  end

  def doi_content(locale, interview)
    template = "/interviews/_doi.#{locale}.html+#{Project.name.to_s}"
    render_to_string(template: template, locals: {interview: interview}, layout: false)
  end
end
