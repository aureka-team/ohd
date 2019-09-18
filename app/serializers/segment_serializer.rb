class SegmentSerializer < ApplicationSerializer
  include IsoHelpers

  attributes :id,
             :interview_id,
             :interview_archive_id,
             :sort_key,
             :time,
             :tape_nbr,
             :tape_count,
             :text,
             :mainheading,
             :subheading,
             :annotations,
             :user_annotation_ids,
             :references_count,
             :registry_references,
             #:references,
             :media_id,
             :timecode,
             :speaker_changed,
             :speaker_id,
             :speaker,
             :translations
             #:speaker_is_interviewee

  belongs_to :speaking_person, serializer: LightPersonSerializer

  def interview_archive_id
    object.interview.archive_id
  end  
  
  def speaker_changed
   object.speaker_changed
  end

  #def speaker_is_interviewee
    #object.speaker_id == object.interview.interviewees.first.id
  #end

  def tape_nbr
    #object.timecode.scan(/\[(\d*)\]/).flatten.first.to_i
    object.tape_number || object.tape.number
  end

  def tape_count
    object.interview.tapes.count
  end

  def annotations
    object.annotations.inject({}){|mem, c| mem[c.id] = ::AnnotationSerializer.new(c); mem}
  end

  def references_count
    object.registry_references.count
  end

  def registry_references
    object.registry_references.inject({}){|mem, c| mem[c.id] = ::RegistryReferenceSerializer.new(c); mem}
  end

  def mainheading
    object.translations.inject({}) do |mem, translation|
      mem[translation.locale] = translation.mainheading
      mem
    end
  end

  def subheading
    object.translations.inject({}) do |mem, translation|
      mem[translation.locale] = translation.subheading
      mem
    end
  end

  def text
    object.transcripts
  end

end
