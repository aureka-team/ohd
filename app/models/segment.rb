require 'globalize'

class Segment < ActiveRecord::Base
  include IsoHelpers

  belongs_to :interview#, inverse_of: :segments
  belongs_to :speaking_person, 
    -> { includes(:translations) },
    class_name: 'Person',
    foreign_key: 'speaker_id'

  belongs_to :tape#, inverse_of: :segments

  has_many  :registry_references,
            -> { includes(registry_entry: {registry_names: :translations}, registry_reference_type: {}) },
            :as => :ref_object,
            :dependent => :destroy

  has_many  :registry_entries,
            through: :registry_references

  # NB: Don't use a :dependent => :destroy or :delete
  # on these, as they are user-generated.
  has_many  :user_annotations, as: :reference
  has_many  :annotations

  scope :with_heading, -> { 
    joins(:translations).
    where("((segment_translations.mainheading IS NOT NULL AND segment_translations.mainheading <> '') OR (segment_translations.subheading IS NOT NULL AND segment_translations.subheading <> ''))").
    includes(:tape, :translations).
    order(:id)}

  scope :mainheadings_until, ->(segment_id, interview_id) { 
    joins(:translations).
    where("(segment_translations.mainheading IS NOT NULL AND segment_translations.mainheading <> '')").
    #where("(segment_translations.subheading IS NULL OR segment_translations.subheading = '')").
    where("segments.id <= ?", segment_id).
    where(interview_id: interview_id).
    includes(:tape, :translations).
    order(:id)}

  scope :subheadings_until, ->(segment_id, interview_id, mainheading_id) { 
    joins(:translations).
    where("(segment_translations.subheading IS NOT NULL AND segment_translations.subheading <> '')").
    where("segments.id <= ?", segment_id).
    where("segments.id >= ?", mainheading_id).
    where(interview_id: interview_id).
    includes(:tape, :translations).
    order(:id)}

  scope :for_media_id, ->(mid) {
    where("segments.media_id < ?", Segment.media_id_successor(mid))
    .order(media_id: :desc)
     .limit(1)
  }


  # ZWAR_MIGRATE: uncomment this in between migrations (after  20170710104214_make_segment_speaker_associated)
  translates :mainheading, :subheading, :text

  validates_presence_of :timecode#, :media_id

  # TODO: rm this: segments won`t change id any more when platform and archive are joined together?!
  # NOTE: NO UNIQUENESS OF MEDIA_ID!
  # due to segment splitting as captions, the media id can be repeated!!
  # validates_uniqueness_of :media_id
  #validates_format_of :media_id, :with => /\A[a-z]{0,2}\d{3}_\d{2}_\d{2}_\d{3,4}\z/i

  validates_associated :interview
  validates_associated :tape

  # TODO: rm this: segments won`t change id any more when platform and archive are joined together?!
  #after_create :reassign_user_content

  before_validation :do_before_validation_on_create, :on => :create

  class << self
    def create_or_update_by(opts={})
      segment = find_or_create_by(interview_id: opts[:interview_id], timecode: opts[:timecode], tape_id: opts[:tape_id])
      assign_speakers_and_update_text(segment, opts)
    end

    # this methods substitutes speaker_designations (e.g. *CG:*) 
    # if these speaker_designations do not occur at the beginning of the text, a new segment will be created for each occurence
    #
    def assign_speakers_and_update_text(segment, opts)
      tape = Tape.find opts[:tape_id]

      speaker_designations = opts[:contribution_data].map{|d| d['speaker_designation']}
      #
      # regexps with capture groups, e.g. /(speaker one:)|(speaker two:)/
      #
      all_speakers_regexp = Regexp.new(speaker_designations.map{|d| "(#{Regexp.quote(d)})"}.join('|'))

      # 
      # splitted_text is an array containing [speaker_designation1, text_of_speaker1, speaker_designation2, text_of_speaker2, etc.]
      #
      splitted_text = opts[:contribution_data].empty? ? [opts[:text]] : opts[:text].split(all_speakers_regexp).reject(&:empty?)  
      time_per_char = calculate_time_per_char(speaker_designations, opts)

      # clean erraneously added blanks
      while splitted_text.first =~ /^[\n+|\s+]$/
        splitted_text.shift
      end

      while !splitted_text.empty?
        if splitted_text.length.even?
          speaker_designation = splitted_text.shift
          text = splitted_text.shift.gsub(/\n+/, '')
          segment.update_attributes text: text, locale: opts[:locale], speaker_id: opts[:contribution_data].select{|c| c['speaker_designation'] ==  speaker_designation}.first['person_id']
        else
          text = splitted_text.shift.gsub(/\n+/, '')
          segment.update_attributes text: text, locale: opts[:locale], speaker_id: segment.prev && segment.prev.speaker_id
        end

        # if there is another speaker_designation in the text
        # check whether there is  an automatically generated segment (from reading in the transcript in another language)
        # or create it
        #
        unless splitted_text.empty?
          next_time = Timecode.new(segment.timecode).time + text.length * time_per_char
          if segment.next && segment.next.timecode < opts[:next_timecode]
            segment = segment.next 
          else
            # if the calculated start-time for the next segment is bigger than the actual tape`s time
            # associate to the next tape
            # set time  of next segment to zero or a given shift
            #
            if next_time > tape.duration
              tape = tape.next
              next_time = tape.time_shift
            end
            segment = create(interview_id: opts[:interview_id], tape_id: tape.id, timecode: Timecode.new(next_time).timecode)
          end
        end
      end
    end

    def calculate_time_per_char(speaker_designations, opts)
      # this regexp has  no capture groups!!
      all_speakers_regexp = Regexp.new(speaker_designations.map{|d| Regexp.quote(d)}.join('|'))
      clean_text = opts[:text].gsub(all_speakers_regexp, '').gsub(/\n+/, '')
      duration = Timecode.new(opts[:next_timecode]).time - Timecode.new(opts[:timecode]).time
      duration/clean_text.length
    end

  end

  def identifier
    id
  end

  def identifier_method
    'id'
  end

  def do_before_validation_on_create
    # Make sure we have a tape assigned.
    if self.tape.nil?
      raise "Interview ID missing." if self.interview_id.nil?

      tape_media_id = (self.media_id || '')[Regexp.new("#{Project.project_initials}\\d{3}_\\d{2}_\\d{2}", Regexp::IGNORECASE)]
      tape = Tape.where({media_id: tape_media_id, interview_id: self.interview_id}).first
      raise "No tape found for media_id='#{tape_media_id}' and interview_id=#{self.interview_id}" if tape.nil?

      self.tape_id = tape.id
    end
  end

  searchable do
    string :archive_id, :stored => true
    string :media_id, :stored => true
    string :timecode
    string :sort_key

    # dummy method, necessary for generic search
    string :workflow_state do
      'public'
    end

    (Project.available_locales + [:orig]).each do |locale|
      text :"text_#{locale}", stored: true
    end
    #dynamic_string :transcripts, stored: true  do # needs to be stored to enable highlighting
      #translations.inject({}) do |mem, translation| 
        #mem["text_#{ISO_639.find(translation.locale.to_s).alpha2}"] = translation.text
        #mem
      #end
    #end
    #
    #
    # the following won`t run because of undefined method `translations' for #<Sunspot::DSL::Fields:0x00000006b9f518>
    #translations.each do |translation| 
      #text :"#{translation.text}", stored: true # needs to be stored to enable highlighting
    #end

    #text :mainheading, :boost => 10 do
      #mainheading = ''
      #translations.each do |translation|
        #mainheading << ' ' + translation.mainheading unless translation.mainheading.blank?
      #end
      #mainheading.strip
    #end
    #text :subheading, :boost => 10 do
      #subheading = ''
      #translations.each do |translation|
        #subheading << ' ' + translation.subheading unless translation.subheading.blank?
      #end
      #subheading.strip
    #end
    #text :registry_entries, :boost => 5 do
      #registry_references.map do |reference|
        #reference.registry_entry.search_string
      #end.join(' ')
    #end
    ## Also index the reference by all parent entries (classification)
    ## of the registry entry and its respective alias names.
    #text :classification, :boost => 6 do
      #registry_references.map do |reference|
        #reference.registry_entry.ancestors.map do |ancestor|
          #ancestor.search_string
        #end.join(' ')
      #end.join(' ')
    #end
    
  end

  (Project.available_locales).each do |locale|
    define_method "text_#{locale}" do 
      text(ISO_639.find(locale).send(Project.alpha))
    end
  end

  def text_orig 
    locale = orig_lang
    text(ISO_639.find(locale).send(Project.alpha))
  end

  def transcripts
    # TODO: rm Nokogiri parser after segment sanitation
    translations.inject({}) do |mem, translation|
      mem[ISO_639.find(translation.locale.to_s).alpha2] = translation.text ? Nokogiri::HTML.parse(translation.text).text.sub(/^:[\S ]/, "").sub(/\*[A-Z]{1,3}:\*[\S ]/, '') : ''
      #mem[ISO_639.find(translation.locale.to_s).alpha2] = translation.text ? Nokogiri::HTML.parse(translation.text).text.sub(/^\S*:\S{1}/, "") : ''
      mem
    end
  end

  def sort_key
    "#{tape_id}.#{timecode}"
  end

  def orig_lang
    interview.language.first_code
  end

  def archive_id
    @archive_id || interview.archive_id
  end

  def archive_id=(code)
    @archive_id = code
  end

  def media_id=(id)
    write_attribute :media_id, id.upcase
  end

  def media_id
    (read_attribute(:media_id) || '').upcase
  end

  #
  # only return speaker attribute if no speaker_id is set
  #
  def speaker_designation
    speaker_id.blank? && speaker
  end

  # return a range of media ids up to and not including the segment's media id
  def media_ids_up_to(segment)
    segment = nil if (segment.tape != self.tape) || (segment.media_id < self.media_id)
    media_index = self.media_id[/\d{4}$/].to_i
    base_media_id = self.media_id.sub(/\d{4}$/,'')
    range_size = 2
    unless segment.nil?
      range_size = segment.media_id[/\d{4}$/].to_i - media_index - 1
    end
    ids = [media_id]
    if range_size > 0
      ids << base_media_id + (media_index + range_size).to_s.rjust(4,'0')
    end
    ids
  end

  def time
    @time ||= Timecode.new(timecode).time
  end

  def next
    tape.segments.where("timecode > ?", read_attribute(:timecode)).first
  end

  def prev
    tape.segments.where("timecode < ?", read_attribute(:timecode)).last
  end

  def alias_names
    interview.alias_names || ''
  end

  def as_vtt_subtitles(lang)
    # TODO: rm strip
    raw_segment_text = text(projectified(lang))
    segment_text = speaker_changed(raw_segment_text) ? raw_segment_text.sub(/:/,"").strip() :  raw_segment_text
    end_time = self.next.try(:time) || 9999
    "#{Time.at(time).utc.strftime('%H:%M:%S.%3N')} --> #{Time.at(end_time).utc.strftime('%H:%M:%S.%3N')}\n#{segment_text}"
  end

  def speaker_changed(raw_segment_text = false)
    # TODO: rm this method after segment sanitation and replace it s occurences
    raw_segment_text && raw_segment_text[1] == ":"
  end

  # returns the segment that leads the chapter
  def section_lead_segment
    Segment.where(["interview_id = ? AND section = ?", interview_id, section]).order(:media_id).first
  end

  def last_heading
    mainheadings = Segment.mainheadings_until(id, interview_id)
    if mainheadings.count > 0
      mainheadings_count = mainheadings.map{|mh| mh.mainheading(projectified(Project.available_locales.first))}.uniq.count
      subheadings = Segment.subheadings_until(id, interview_id, mainheadings.last.id)
      
      if subheadings.count > 0
        I18n.available_locales.inject({}) do |mem, locale|
          mem[locale] = "#{mainheadings_count}.#{subheadings.count}. #{subheadings.last.subheading(projectified(locale))}"
          mem
        end
      else
        I18n.available_locales.inject({}) do |mem, locale|
          mem[locale] = "#{mainheadings_count}. #{mainheadings.last.mainheading(projectified(locale))}"
          mem
        end
      end
    else
      {}
    end
  end

  def has_heading?
    translation_with_heading = translations.detect do |t|
      not (t.mainheading.blank? and t.subheading.blank?)
    end
    not translation_with_heading.nil?
  end

  def self.media_id_successor(mid)
    Segment.media_id_diff(mid, 1)
  end

  def self.media_id_predecessor(mid)
    Segment.media_id_diff(mid, -1)
  end

  def self.media_id_diff(mid, diff)
    mid.sub(/\d{4}$/,(mid[/\d{4}$/].to_i + diff.to_i).to_s.rjust(4,'0'))
  end

  private

  # remove workflow comments
  def filter_annotation(text)
    #text.gsub(/\{[\s{]+[^{}]+[\s}]+\}\s?/,'')
    (text || '').gsub(/\{[\s{]+[^{}]+[\s}]+\}\s?/,'')
  end

  # This is used to reassociate all segment-based user_content,
  # i.e. user_annotations and their annotations.
  def reassign_user_content
    # As we don't know the subsequent segments media_id yet,
    # theoretically all the trailing annotations would have to
    # be assigned to each segment, so that annotations on the last
    # segment get assigned to each of the interviews segments in turn.
    # To avoid this, I'm using an arbitrary media_id range of media_id..media_id+12
    # which in practice should be safe for reassigning to the correct segment, while
    # minimizing subsequent reassignments.
    UserAnnotation.where(["media_id >= ? AND media_id < ?", media_id, Segment.media_id_diff(media_id, 12)]).
      includes(:annotation).find_each do |user_annotation|
        user_annotation.update_attribute :reference_id, self.id
        unless user_annotation.annotation.nil?
          user_annotation.annotation.update_attribute :segment_id, self.id
        end
      end
  end

end
