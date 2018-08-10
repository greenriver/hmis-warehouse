module Health
  class EpicSsm < EpicBase

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_ssms
    has_one :patient, through: :epic_patient

    self.source_key = :NOTE_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        NOTE_ID: :id_in_source,
        PAT_ENC_CSN_ID: :encounter_id,
        ENCOUNTER_TYPE: :encounter_type,
        UPDATE_DATE: :ssm_updated_at,
        USER_NAME: :staff,
        NOTE_TEXT_1: :part_1,
        NOTE_TEXT_2: :part_2,
        NOTE_TEXT_3: :part_3,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def text
      [
        part_1,
        part_2,
        part_3,
      ].join().gsub('  ', "\n")
    end
  end
end
