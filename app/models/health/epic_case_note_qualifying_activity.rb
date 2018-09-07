module Health
  class EpicCaseNoteQualifyingActivity < EpicBase
    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_case_note_qualifying_activities
    belongs_to :epic_case_note, primary_key: :id_in_source, foreign_key: :epic_case_note_source_id, inverse_of: :epic_case_note_qualifying_activities

    self.source_key = :NOTE_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        NOTE_ID: :id_in_source,
        PAT_ENC_CSN_ID: :epic_case_note_source_id,
        ENCOUNTER_TYPE: :encounter_type,
        UPDATE_DATE: :update_date,
        USER_NAME: :staff,
        NOTE_TEXT_1: :part_1,
        NOTE_TEXT_2: :part_2,
        NOTE_TEXT_3: :part_3,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def self.clean_value key, value
      value = case value
      when 'NULL'
        nil
      else
        value.presence
      end
      super(key, value)
    end
  end
end