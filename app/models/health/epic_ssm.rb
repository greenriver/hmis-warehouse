###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicSsm < EpicBase
    phi_patient :patient_id

    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :encounter_id, Phi::OtherIdentifier
    # phi_attr :encounter_type
    phi_attr :ssm_updated_at, Phi::Date
    phi_attr :staff, Phi::SmallPopulation
    phi_attr :part_1, Phi::FreeText
    phi_attr :part_2, Phi::FreeText
    phi_attr :part_3, Phi::FreeText

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_ssms
    has_one :patient, through: :epic_patient

    scope :updated_within_range, -> (range) do
      where(ssm_updated_at: range)
    end
    scope :after_enrollment_date, -> do
      joins(patient: :patient_referral).
      where(arel_table[:ssm_updated_at].gteq(hpr_t[:enrollment_start_date]))
    end

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
