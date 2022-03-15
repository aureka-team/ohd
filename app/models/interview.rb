require 'globalize'
require 'webvtt'
require "#{Rails.root}/lib/reference_tree.rb"
require "#{Rails.root}/lib/timecode.rb"

class Interview < ApplicationRecord
  include OaiRepository::Set
  include ActiveModel::Validations

  belongs_to :project
  belongs_to :collection
  belongs_to :language

  has_many :photos,
           #-> {includes(:interview, :translations)},
           :dependent => :destroy

  # TODO: is this still necessary for zwar
  #has_many :text_materials,
           #:dependent => :destroy

  has_many :tapes,
           -> {
                  includes(:interview).
                  order(:number)
           },
           dependent: :destroy,
           inverse_of: :interview

  has_many :annotations,
           #-> {includes(:translations)},
           :dependent => :delete_all

  has_many :contributions,
           :dependent => :delete_all

  has_many :contributors,
           :class_name => 'Person',
           :source => :person,
           :through => :contributions

  has_many :registry_references,
           -> {includes(registry_entry: {registry_names: :translations}, registry_reference_type: {})},
           :as => :ref_object,
           :dependent => :destroy

  has_many :registry_entries,
           :through => :registry_references

  has_many :segments,
           -> { order(:tape_number, :timecode) },
           dependent: :destroy
           #inverse_of: :interview

  has_many :segment_registry_references,
           -> {
              includes(registry_entry: {registry_names: :translations}, registry_reference_type: {}).
              where("registry_references.ref_object_type='Segment'").
              where("registry_references.registry_entry_id != '0'")
           },
           class_name: 'RegistryReference'

  has_many :segment_registry_entries,
           through: :segment_registry_references,
           source: :registry_entry

  has_many :checklist_items,
           -> {order('item_type ASC')},
           dependent: :destroy

  has_many :tasks, dependent: :destroy

  has_and_belongs_to_many :archiving_batches

  serialize :properties

  after_create :set_public_attributes_to_properties
  def set_public_attributes_to_properties
    atts = %w(archive_id media_type interview_date duration tape_count language_id collection_id description)
    update_attributes properties: (properties || {}).update(public_attributes: atts.inject({}){|mem, att| mem[att] = "true"; mem})
  end

  after_create :create_tasks
  def create_tasks
    project.task_types.each do |task_type|
      Task.create(interview_id: id, task_type_id: task_type.id)
    end
  end

  translates :observations, :description, fallbacks_for_empty_translations: true, touch: true

  accepts_nested_attributes_for :translations, :contributions

  class ProjectConfigValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors.add attribute, (options[:message] || "not a valid archive_id in this project") unless
        value =~ /^#{record.project.shortname}\d{#{record.project.archive_id_number_length}}$/
    end
  end

  validates_associated :collection
  validates :archive_id, presence: true, uniqueness: true, project_config: true
  validates :media_type, inclusion: {in: %w(video audio)}
  validates :original_content_type, format: { with: /\A\w+\/[-+.\w]+\z/ }, allow_nil: true

  #has_one_attached :still_image

  searchable do
    integer :project_id, :stored => true, :references => Project
    integer :language_id, :stored => true, :references => Language
    string :archive_id, :stored => true, :references => Interview
    # in order to be able to search for archive_id with fulltextsearch
    text :archive_id, :stored => true
    integer :interviewee_id, :stored => true#, :references => Person
    integer :collection_id, :stored => true, :references => Collection
    integer :tasks_user_account_ids, :stored => true, :multiple => true
    integer :tasks_supervisor_ids, :stored => true, :multiple => true
    string :workflow_state, stored: true

    # in order to find pseudonyms with fulltextsearch (dg)
    #(text :pseudonym_string, :stored => true) if project.identifier == 'dg'

    # in order to fast access a list of titles for the name and alias_names autocomplete:
    string :title, :stored => true do
      Rails.configuration.i18n.available_locales.inject({}) do |mem, locale|
        mem[locale] = title(locale)
        mem
      end
    end
    string :media_type, :stored => true
    string :duration, :stored => true
    string :language, :stored => true do
      language && language.translations.map(&:name).join(' ')
    end
    string :alias_names, :stored => true

    # in order to fast access places of birth for all interviews
    # string :birth_location, :stored => true

    text :transcript do
      segments.includes(:translations).inject([]) do |all, segment|
        all << segment.translations.inject([]){|mem, t| mem << t.text; mem}.join(' ')
        all
      end.join(' ')
    end

    text :headings do
      segments.with_heading.inject([]) do |all, segment|
        all << segment.translations.inject([]){|mem, t| mem << "#{t.mainheading} #{t.subheading}"; mem}.join(' ')
        all
      end.join(' ')
    end

    dynamic_string :search_facets, :multiple => true, :stored => true do
      project.search_facets.inject({}) do |mem, facet|
        mem[facet.name] = (self.respond_to?(facet.name) ? self.send(facet.name) : (interviewee && interviewee.send(facet.name))) || ''
        mem
      end
    end

    Rails.configuration.i18n.available_locales.each do |locale|
      text :"observations_#{locale}", stored: true do
        if index_observations?
          observations(locale)
        else
          ''
        end
      end

      string :"person_name_#{locale}", :stored => true do
        if full_title(locale)
          title = full_title(locale).mb_chars.normalize(:kd)
          Rails.configuration.mapping_to_ascii.each{|k,v| title = title.gsub(k,v)}
          title.downcase.to_s
        end
      end
      text :"person_name_#{locale}", :stored => true do
        full_title(locale)
      end

      string :"alias_names_#{locale}", :stored => true do
        (interviewee && interviewee.alias_names(locale)) || ''
      end
      text :"alias_names_#{locale}", :stored => true do
        (interviewee && interviewee.alias_names(locale)) || ''
      end

      # contributions
      # find them through fulltext search
      # e.g.: 'Kamera Hans Peter'
      #
      text :"contributions_#{locale}" do
        contributions.map do |c|
          if c.person
            [I18n.t("contributions.#{c.contribution_type}", locale: locale), c.person.first_name(locale), c.person.last_name(locale)]
          end
        end.flatten.join(' ')
      end

      # biographical entries texts
      #
      text :"biography_#{locale}" do
        if interviewee
          interviewee.biographical_entries.map{|b| b.text(locale)}.join(' ')
        else
          ''
        end
      end

      # photo caption texts
      #
      text :"photo_captions_#{locale}" do
        photos.map{|p| p.caption(locale)}.join(' ')
      end

      # annotations
      text :"annotations_#{locale}" do
        annotations.map{|a| a.text(locale)}.join(' ')
      end
    end

    text :interviewer_property do
      properties && properties[:interviewer]
    rescue StandardError => e
      puts "*** #{self.id}"
    end

  end

  scope :shared, -> {where(workflow_state: 'public')}
  scope :with_media_type, -> {where.not(media_type: nil)}

  def interviewee_id
    interviewees.first && interviewees.first.id
  end

  %w(interviewee interviewer transcriptor translator cinematographer quality_manager proofreader segmentator research).each do |contributor|
    define_method contributor.pluralize do
      contributions.joins(:contribution_type).where("contribution_types.code = ?", contributor).map(&:person)
    end
  end

  def biographies_workflow_state=(change)
    interviewees.each do |interviewee|
      interviewee.biographical_entries.each do |bio|
        bio.update_attribute :workflow_state, change
      end
    end
  end

  def public_attributes=(hash)
    public_atts = self.properties[:public_attributes].with_indifferent_access.update("#{hash.keys.first}": hash.values.first)
    self[:properties] = self.properties.update(public_attributes: public_atts)
  end

  def self.non_public_method_names
    %w(title short_title description contributions photos registry_references)
  end

  def tasks_user_account_ids
    tasks.map(&:user_account_id).compact.uniq
  end

  def tasks_supervisor_ids
    tasks.map(&:supervisor_id).compact.uniq
  end

  def tape_count=(d)
    # dummy: build did not do the trick here. Therefore I implemented find_or_create_tapes
  end

  def tape_count
    tapes.count
  end

  def find_or_create_tapes(d)
    tapes.where.not("media_id LIKE ?", "#{archive_id.upcase}_#{format('%02d', d.to_i)}_%").each do |tape|
      if tape.segments.count == 0
        tape.destroy
      else
        tape.update_attributes media_id: "#{archive_id.upcase}_#{format('%02d', d.to_i)}_#{format('%02d', tape.number)}"
      end
    end

    tapes.each do |tape|
      archive_id, tc, tn = tape.media_id.split('_')
      if tape.segments.count == 0 && tn > tc
        tape.destroy
      end
    end

    (1..d.to_i).each do |t|
      tp = Tape.find_or_create_by(media_id: "#{archive_id.upcase}_#{format('%02d', d.to_i)}_#{format('%02d', t)}", number: t, interview_id: id)
    end
    self.touch
  end

  def self.random_featured(n = 1, project_id)
    if n == 1
      shared.where(project_id: project_id).with_media_type.order(Arel.sql('RAND()')).first || first
    else
      shared.where(project_id: project_id).with_media_type.order(Arel.sql('RAND()')).first(n) || first(n)
    end
  end

  def identifier
    archive_id
  end

  def identifier_method
    'archive_id'
  end

  # referenced by archive_id
  def to_param
    archive_id
  end

  def alias_names
    I18n.available_locales.inject({}) do |mem, locale|
      mem[locale] = (interviewee.respond_to? :alias_names) ? interviewee.alias_names(locale) : nil
      mem
    end
  end

  def to_s(locale = I18n.locale)
    short_title(locale)
  end

  def interviewee
    # caching results in 'singleton can't be dumped'-error here. Why?
    #
    #Rails.cache.fetch("#{project.cache_key_prefix}-interviewee-for-#{id}-#{updated_at}") do
      interviewees.first
    #end
  end

   def place_of_interview
     ref = registry_references.where(registry_reference_type: RegistryReferenceType.where(code: 'interview_location')).first
     ref && ref.registry_entry
   end

  def title(locale)
    full_title(locale)
  end

  def reverted_short_title(locale)
    begin
      [interviewee.last_name(locale) || interviewee.last_name(I18n.defaut_locale), interviewee.first_name(locale) || interviewee.first_name(I18n.default_locale)].join(', ')
    rescue
      "Interviewee might not be in DB, interview-archive_id = #{archive_id}"
    end
  end

  after_initialize do
    if project
      project.registry_reference_type_metadata_fields.each do |field|
        define_singleton_method field.name do
          case field["ref_object_type"]
          when "Person"
            (interviewee && interviewee.registry_references.where(registry_reference_type_id: field.registry_reference_type_id).map(&:registry_entry_id)) || []
          when "Interview"
            registry_references.where(registry_reference_type_id: field.registry_reference_type_id).map(&:registry_entry_id)
          when "Segment"
            segment_registry_references.where(registry_reference_type_id: field.registry_reference_type_id).map(&:registry_entry_id).uniq
          else
            []
          end
        end
      end

      OaiRepository.repository_name = project.name[project.default_locale]
      OaiRepository.repository_url = project.archive_domain
      OaiRepository.record_prefix = project.archive_domain
      OaiRepository.admin_email = project.contact_email
    end
  end

  def lang
    # return only the first language code in cases like 'slk/ces'
    language && ( ISO_639.find(language.first_code).try(:alpha2) || language.first_code )
  end

  def languages
    if segments.first
      segments.first.languages
    elsif language
      [ISO_639.find(language.first_code).try(:alpha2) || language.first_code]
    else
      []
    end
  end

  def has_transcript?(locale)
    segment_count = Segment
      .joins(:translations)
      .where('segments.interview_id': id, 'segment_translations.locale': "#{locale}-public")
      .count
    segment_count > 0
  end

  def observations_for_latex(locale)
    escaped_text = LatexToPdf.escape_latex(observations(locale))
    escaped_text.gsub(/\r?\n/, '~\newline~')
  end

  def index_observations?
    public_attributes = properties.fetch(:public_attributes, {})
    observations_public = public_attributes.fetch('observations', true)

    if observations_public != true
      false
    else
      field = project.metadata_fields.where(name: 'observations').first
      if field.present?
        field.use_in_details_view
      else
        true
      end
    end
  end

  def to_vtt(lang, tape_number=1)
    vtt = "WEBVTT\n"
    tapes.where(number: tape_number).first.segments.includes(:translations).each_with_index do |segment, index |
      vtt << "\n#{index + 1}\n#{segment.as_vtt_subtitles(lang)}\n"
    end
    vtt
  end

  def to_ods(locale, tape_number=1)
    CSV.generate(headers: true, col_sep: ";", row_sep: :auto, quote_char: "\x00") do |csv|
      csv << %w(Timecode Speaker Transkript)

      tapes[tape_number.to_i - 1].segments.each do |segment|
        contribution = contributions.where(person_id: segment.speaker_id).first
        speaker_designation = contribution && contribution.speaker_designation
        csv << [segment.timecode, speaker_designation || "", segment.text_translations[locale] || segment.text_translations["#{locale}-public"]]
      end
    end
  end

  #
  # speaker designations from column speaker of table segments
  #
  def speaker_designations
    speakers = []
    segments.find_each(batch_size: 200) do |segment|
      speakers << segment.speaker_designation
    end
    speakers.flatten.uniq.compact.reject{|s| s == false}
  end

  def alpha3_transcript_locales
    language ? language.code.split(/[\/-]/) : []
  end

  def right_to_left
    language && language.code == 'heb' ? true : false
  end

  def create_or_update_segments_from_spreadsheet(file_path, tape_id, locale, update_only_speakers)
    ods = Roo::Spreadsheet.open(file_path)
    ods.each_with_pagename do |name, sheet|
      parsed_sheet = sheet.parse(timecode: /^Timecode|In$/i, transcript: /^Trans[k|c]ript|Translation|Übersetzung$/i, speaker: /^Speaker|Sprecher$/i)
      parsed_sheet.each_with_index do |row, index|
        contribution = contributions.select{|c| c.speaker_designation == row[:speaker]}.first
        speaker_id = contribution && contribution.person_id
        if row[:timecode] =~ /^\[*\d{2}:\d{2}:\d{2}([:.,]{1}\d{2,3})*\]*$/
          if update_only_speakers && speaker_id
            segment = Segment.find_or_create_by(interview_id: id, timecode: row[:timecode], tape_id: tape_id)
            segment.update_attributes speaker_id: speaker_id
          else
            Segment.create_or_update_by({
              interview_id: id,
              timecode: row[:timecode],
              next_timecode: (parsed_sheet[index+1] && parsed_sheet[index+1][:timecode]) || Timecode.new(Tape.find(tape_id).duration).timecode,
              tape_id: tape_id,
              text: row[:transcript] || '',
              locale: locale,
              speaker_id: speaker_id
            })
          end
        end
      end
    end
  rescue  Roo::HeaderRowNotFoundError
    'header_row_not_found'
  end

  # tape_id is a dummy here
  def create_or_update_segments_from_text(file_path, tape_id, locale)
    tape = Tape.find(tape_id)
    data = File.read file_path
    text = Yomu.read :text, data
    Segment.create_or_update_by({
      interview_id: id,
      timecode: Timecode.new(tape.time_shift).timecode,
      next_timecode: Timecode.new(tape.duration).timecode,
      tape_id: tape_id,
      text: text,
      locale: locale
    })
  end

  def create_or_update_segments_from_vtt(file_path, tape_id, locale)
    extension = File.extname(file_path).strip.downcase[1..-1]
    webvtt = extension == 'vtt' ? ::WebVTT.read(file_path) : WebVTT.convert_from_srt(file_path)
    webvtt.cues.each do |cue|
      #
      # get speaker_id
      #
      speaker_match = cue.text.match(/<v (\S+)>/)
      speaker_designation = speaker_match && speaker_match[1]
      contribution = contributions.select{|c| c.speaker_designation == speaker_designation}.first
      speaker_id = contribution && contribution.person_id
      #
      # cut speaker-tag
      #
      text = cue.text.sub(/<v \S+> /, '')

      Segment.create_or_update_by({
        interview_id: id,
        timecode: cue.start.to_s,
        next_timecode: cue.end.to_s,
        tape_id: tape_id,
        text: text,
        locale: locale,
        speaker_id: speaker_id
      })
    end
  end

  # Sets the duration either as an integer in seconds,
  # or applies a timecode by parsing. Even sub-timecodes
  # such as HH:MM are allowed.
  def duration=(seconds_or_timecode)
    time = seconds_or_timecode.to_i
    if seconds_or_timecode.is_a?(String)
      unless seconds_or_timecode.index(':').nil?
        case seconds_or_timecode.count(':.')
          when 2
            seconds_or_timecode << '.00'
          when 1
            seconds_or_timecode << ':00.00'
        end
        time = Timecode.new(seconds_or_timecode).time
      end
    end
    write_attribute :duration, time
  end

  # add the duration of all existing tapes
  def recalculate_duration!
    unless segments.blank? || tapes.blank? || tapes.empty? || (tapes.select{|t| t.duration.nil? }.size > 0)
      new_duration = tapes.inject(0){|dur, t| dur += (t.duration == 0 || t.duration.nil?) ? (td = t.estimated_duration; td && td.time) : Timecode.new(t.duration).time }
      update_attribute(:duration, new_duration) unless new_duration == self[:duration]
    end
  end

  def build_full_title_from_name_parts(locale)
    first_interviewee = interviewee
    if first_interviewee

      # Build last name with a locale-specific pattern.
      last_name = first_interviewee.last_name(locale) || first_interviewee.last_name(I18n.default_locale)
      birth_name = first_interviewee.birth_name(locale) || first_interviewee.birth_name(I18n.default_locale)
      lastname_with_birthname = [last_name, birth_name].compact.join(' ')

      # Build first name.
      first_names = []
      first_name = first_interviewee.first_name(locale) || first_interviewee.first_name(I18n.default_locale)
      first_names << first_name unless first_name.blank?
      other_first_names = first_interviewee.other_first_names(locale) || first_interviewee.other_first_names(I18n.default_locale)
      first_names << other_first_names unless other_first_names.blank?

      # Combine first and last name with a locale-specific pattern.
      if first_names.empty?
        lastname_with_birthname
      else
        "#{lastname_with_birthname}, #{first_names.join(' ')}"
      end
    else
      'no interviewee given'
    end
  end

  def full_title(locale)
    build_full_title_from_name_parts(locale)
  end

  def short_title(locale)
    begin
      [interviewee.first_name(locale), interviewee.last_name(locale)].join(' ')
    rescue
      "Interviewee might not be in DB, interview-id = #{id}"
    end
  end

  def anonymous_title(locale=project.default_locale)
    if project.fullname_on_landing_page
      title(locale)
    else
      name_parts = []
      unless interviewees.blank?
        name_parts << interviewee.first_name(locale) unless interviewee.first_name(locale).blank?
        name_parts << "#{(interviewee.last_name(locale).blank? ? '' : interviewee.last_name(locale)).strip.chars.first}."
      end
      name_parts.join(' ')
    end
  end

  def video
    I18n.t("search_facets.#{media_type}")
  end

  def video?
    media_type == 'video'
  end

  def has_headings?
    segments.with_heading.count > 0 ? true : false
  end

  def segmented?
    !segments.empty?
  end

  def citation_hash
    {
        :original => read_attribute(:original_citation),
        :translated => read_attribute(:translated_citation),
        :item => ((read_attribute(:media_id) || '')[/\d{2}_\d{4}$/] || '')[/^\d{2}/].to_i,
        :position => Timecode.new(read_attribute(:citation_timecode)).time.round
    }
  end

  # TODO: remove or replace this
  # segmented, researched, proofread
  def set_workflow_flags!
    if segments.size > 0
      write_attribute :segmented, true
      if segments.with_heading.size > 0
        write_attribute :researched, true
      end
      unless proofreaders(I18n.default_locale).blank?
        write_attribute :proofread, true
      end
      save
    end
  end

  # TODO: remove or replace this
  # Creates a task that marks the interview as prepared for research
  # Also set the segmentation_state and workflow_state on the Segmentation task
  def prepare!
    self.reload
    if self.segments.empty?
      false
    else
      segmentation_task = self.tasks.for_workflow('Segmentation').first
      # instead of requiring a complete segmentation task - make it so!
      segmentation_task = self.tasks.create do |task|
        task.workflow_type = 'Segmentation'
      end if segmentation_task.nil?
      Task.update_all "workflow_state = 'completed'", ['id = ?', segmentation_task.id]
      changed = if self.qm_value.to_f > 1
                  if self.tasks.for_workflow('Research').empty?
                    # create the research task
                    self.tasks.create do |task|
                      task.workflow_type = 'Research'
                    end
                    true
                  else
                    false
                  end
                else
                  # remove all tasks that don't have anyone assigned
                  unless self.tasks.for_workflow('Research').empty?
                    research_task = self.tasks.for_workflow('Research').first
                    if research_task.responsible.nil?
                      research_task.destroy
                      true
                    else
                      false
                    end
                  end
                end
      skip_versioning!
      update_attribute :segmentation_state, 'qm'
      save
      changed
    end
  end

  def oai_dc_identifier
    archive_id
    "oai:#{project.identifier}:#{archive_id}"
  end

  def oai_dc_creator
    anonymous_title
  end

  def oai_dc_subject
    project.registry_reference_type_metadata_fields.where(use_in_results_table: true, ref_object_type: 'Interview').each do |field|
      "#{field.label(project.default_locale)}: #{self.send(field.name).map{|f| RegistryEntry.find(f).to_s(project.default_locale)}.join(';')}"
    end
  end

  def oai_dc_description
    "Lebensgeschichtliches #{self.video}-Interview in #{self.language.name.downcase}er Sprache mit Transkription, deutscher Übersetzung, Erschließung, Kurzbiografie und Fotografien"
  end

  def oai_dc_publisher
    "Interview-Archiv \"#{project.name('de')}\""
  end

  def oai_dc_contributor
    oai_contributors = [
      %w(interviewers Interviewführung),
      %w(cinematographers Kamera),
      %w(transcriptors Transkripteur),
      %w(translators Übersetzer),
      %w(segmentators Erschließer)
    ].inject([]) do |mem, (contributors, contribution)|
      if self.send(contributors).length > 0
        "#{contribution}: " + self.send(contributors).map{|contributor| "#{contributor.last_name(project.default_locale)}, #{contributor.first_name(project.default_locale)}"}.join('; ')
      end
      mem
    end
    if !project.cooperation_partner.blank?
      oai_contributors << "Kooperationspartner: #{project.cooperation_partner}"
    end
    oai_contributors << "Projektleiter: #{project.leader}"
    oai_contributors << "Projektmanager: #{project.manager}"
    oai_contributors << "Hosting Institution: #{project.hosting_institution}"
    oai_contributors.join('. ')
  end

  def oai_dc_date
    self.interview_date && Date.parse(self.interview_date).strftime("%d.%m.%Y")
  end

  #def oai_dc_type
  #end

  def oai_dc_format
    self.video
  end

  #def oai_dc_source
  #end

  def oai_dc_language
    language && language.name
  end

  #def oai_dc_relation
  #end

  #def oai_dc_coverage
  #end

  #def oai_dc_rights
  #end

  def type
    'Interview'
  end

  class << self
    # https://github.com/sunspot/sunspot#stored-fields
    # in order to get a dropdown list in search field
    def dropdown_search_values(project, user_account)
      wf_state = user_account && (user_account.admin? || user_account.roles?(project, 'General', 'edit')) ? ["public", "unshared"] : 'public'
      cache_key_date = [Interview.maximum(:updated_at), Person.maximum(:updated_at), (project ? project.updated_at : Project.maximum(:updated_at))]
        .compact.max.strftime("%d.%m-%H:%M")

      Rails.cache.fetch("#{project ? project.cache_key_prefix : 'ohd'}-dropdown-search-values-#{wf_state}-#{cache_key_date}") do
        search = Interview.search do
          adjust_solr_params do |params|
            params[:rows] = project ? project.interviews.size : Interview.count
          end
          with(:workflow_state, wf_state)
          with(:project_id, project.id) if project
        end

        {
          all_interviews_titles: search.hits.map{|hit| eval hit.stored(:title)},
          # => [{:de=>"Fomin, Dawid Samojlowitsch", :en=>"Fomin, Dawid Samojlowitsch", :ru=>"Фомин Давид Самойлович"},
          #    {:de=>"Jusefowitsch, Alexandra Maximowna", :en=>"Jusefowitsch, Alexandra Maximowna", :ru=>"Юзефович Александра Максимовна"},
          #    ...]
          all_interviews_pseudonyms: search.hits.map{|hit| eval hit.stored(:alias_names)}
          #all_interviews_birth_locations: search.hits.map{|hit| hit.stored(:birth_location)}
        }
      end
    end

    def archive_search(user_account, project, locale, params, per_page = 12)
      search = Interview.search do
        fulltext params[:fulltext]
        with(:workflow_state, user_account && (user_account.admin? || user_account.roles?(project, 'General', 'edit')) ? ['public', 'unshared'] : 'public')
        with(:project_id, project.id) if project
        with(:archive_id, params[:archive_id]) if params[:archive_id]
        if project
          dynamic :search_facets do
            facet *project.search_facets_names
            project.search_facets_names.each do |facet|
              facet_value = params[facet]
              facet_value.delete_if(&:blank?) if facet_value.is_a?(Array)
              with(facet.to_sym).any_of(facet_value) unless facet_value.blank?
            end
          end
        end

        # Order
        # TODO: sort linguistically
        if params[:fulltext].blank? && params[:order].blank?
          if project && project.default_search_order == 'collection'
            order_by(:collection_id, :asc)
            order_by("person_name_#{locale}".to_sym, :asc)
          else
            order_by("person_name_#{locale}".to_sym, :asc)
          end
        elsif params[:order]
          order_by(params[:order].split('-')[0].to_sym, params[:order].split('-')[1].to_sym)
        else
          order_by(:score, :desc)
          order_by("person_name_#{locale}".to_sym, :asc)
        end

        # Pagination
        paginate page: params[:page] || 1, per_page: per_page
      end
    end

    def archive_ids_by_alphabetical_order(locale = :en)
      all.sort_by{ |i| i.full_title(locale) }.map(&:archive_id)
      # joins(contributions: {person: :translations}).
      #   where("contributions.contribution_type = ?", "interviewee").
      #   order("person_translations.last_name", "person_translations.first_name").
      #   map(&:archive_id).uniq
    end
  end
end
