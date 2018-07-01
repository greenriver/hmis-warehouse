module Health
  class EpicCaseNote < Base
    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_case_notess

    self.source_key = :PAT_ENC_CSN_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        PAT_ENC_CSN_ID: :id_in_source,
        CONTACT_DATE: :contact_date,
        ENC_CLOSED_YN: :closed,
        ENC_TYPE: :encounter_type,
        PROV_NAME: :provider_name,
        LOCATION: :location,
        CHIEF_COMPLAINT_1: :chief_complaint_1,
        CC1_COMMENT: :chief_complaint_1_comment,
        CHIEF_COMPLAINT_2: :chief_complaint_2,
        CC2_COMMENT: :chief_complaint_2_comment,
        DX_1_ICD10: :dx_1_icd10,
        DX_1_NAME: :dx_1_name,
        DX_2_ICD10: :dx_2_icd10,
        DX_2_NAME: :dx_2_name,
        HOMELESS_STATUS: :homeless_status,
      }
    end

  end
end