###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicCaseNote < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, 'ID of Epic case note'
    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :contact_date, Phi::Date, 'Date of contact'
    # phi_attr :closed
    # phi_attr :encounter_type
    phi_attr :provider_name, Phi::SmallPopulation, 'Name of provider'
    phi_attr :location, Phi::Location, 'Location of encounter'
    phi_attr :chief_complaint_1, Phi::FreeText
    phi_attr :chief_complaint_1_comment, Phi::FreeText
    phi_attr :chief_complaint_2, Phi::FreeText
    phi_attr :chief_complaint_2_comment, Phi::FreeText
    phi_attr :dx_1_icd10, Phi::SmallPopulation
    phi_attr :dx_1_name, Phi::FreeText
    phi_attr :dx_2_icd10, Phi::SmallPopulation
    phi_attr :dx_2_name, Phi::FreeText
    # phi_attr :homeless_status

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_case_notes, optional: true
    has_many :patient, through: :epic_patient
    has_many :epic_case_note_qualifying_activities, primary_key: :id_in_source, foreign_key: :epic_case_note_source_id, inverse_of: :epic_case_note

    scope :with_housing_status, -> do
      where.not(homeless_status: [nil, ''], contact_date: nil)
    end
    scope :within_range, ->(range) do
      where(contact_date: range)
    end

    self.source_key = :PAT_ENC_CSN_ID

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
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
