class EditTableImport

  attr_accessor :file_path, :sheet, :interview, :contributions,
    :original_locale, :only_references, :locale

  def initialize(interview, file_path, locale, only_references=false)
    @interview = interview
    @contributions = @interview.contributions_hash
    @original_locale = @interview.alpha3
    @file_path = file_path
    @locale = locale
    @only_references = only_references
    @sheet = parse_sheet
  end

  def parse_sheet
    csv = Roo::Spreadsheet.open(file_path, { csv_options: CSV_OPTIONS })
    if csv.first.length == 1
      csv = Roo::Spreadsheet.open(file_path, { csv_options: CSV_OPTIONS.merge(col_sep: ";") })
    end

    unless only_references
      interview.tapes.destroy_all
      interview.find_or_create_tapes(csv.cell(csv.last_row, 1).to_i)
    end

    csv.sheet('default').parse(interview.edit_table_headers(locale))
  end

  def process
    sheet.each do |row|
      unless only_references
        speaker_id = contributions.key(row[:speaker_designation])

        translations_attributes = []
        (interview.alpha3s | interview.project.available_locales.map{|l| ISO_639.find(l).alpha3}).each do |locale|
          text = nil
          if locale == original_locale
            text = row[:transcript]
          else
            text = row["translation_#{locale}".to_sym]
          end

          translations_attributes << {
            locale: locale,
            text: text,
            mainheading: row["mainheading_#{locale}".to_sym],
            subheading: row["subheading_#{locale}".to_sym],
          } if text || row["mainheading_#{locale}".to_sym] || row["subheading_#{locale}".to_sym]
        end

        segment = Segment.create!(
          interview_id: interview.id,
          tape_id: interview.tapes.where(number: row[:tape_number]).first.id,
          speaker_id: speaker_id,
          timecode: row[:timecode],
          translations_attributes: translations_attributes
        )
        segment.update_has_heading
        create_annotations(row, interview, segment)
      else
        segment = interview.tapes.where(number: row[:tape_number]).first.
          segments.where(timecode: row[:timecode]).first
        interview.project.available_locales.map{|l| ISO_639.find(l).alpha3}.each do |locale|
          segment.update(
            mainheading: row["mainheading_#{locale}".to_sym],
            subheading: row["subheading_#{locale}".to_sym],
            locale: locale,
            has_heading: true
          ) if row["mainheading_#{locale}".to_sym] || row["subheading_#{locale}".to_sym]
        end
      end
      create_references(row, interview, segment)
    end
  end

  def create_references(row, interview, ref_object)
    row[:registry_references] && row[:registry_references].split('#').each do |registry_entry_id|
      registry_entry = RegistryEntry.find(registry_entry_id) rescue nil
      if registry_entry
        RegistryReference.create(
          registry_entry_id: registry_entry_id,
          ref_object_id: ref_object.id,
          ref_object_type: ref_object.class.name,
          ref_position: 0,
          original_descriptor: "",
          ref_details: "",
          ref_comments: "",
          ref_info: "",
          workflow_state: "checked",
          interview_id: interview.id
        )
        registry_entry && registry_entry.touch
      end
    end
  end

  def create_annotations(row, interview, segment)
    annotations_with_translations = {}
    interview.alpha3s.map do |alpha3|
      annotations_with_translations[alpha3] = row["annotation_#{alpha3}".to_sym]&.split('#')
    end

    original = annotations_with_translations[interview.alpha3]
    if original
      while original&.length > 0
        translations_attributes = []
        interview.alpha3s.each do |alpha3|
          translations_attributes << {
            text: annotations_with_translations[alpha3]&.pop,
            locale: alpha3
          }
        end

        Annotation.create(
          segment_id: segment.id,
          interview_id: interview.id,
          workflow_state: "public",
          translations_attributes: translations_attributes
        )
      end
    end
  end
end
