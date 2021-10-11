###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicCha < EpicBase
    phi_patient :patient_id

    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :encounter_id, Phi::OtherIdentifier, "ID of encounter"
    # phi_attr :encounter_type
    phi_attr :cha_updated_at, Phi::Date
    phi_attr :staff, Phi::SmallPopulation, "Name of staffs"
    # phi_attr :provider_type
    phi_attr :reviewer_name, Phi::SmallPopulation, "Name of reviewer"
    # phi_attr :reviewer_provider_type
    phi_attr :part_1, Phi::FreeText
    phi_attr :part_2, Phi::FreeText
    phi_attr :part_3, Phi::FreeText
    phi_attr :part_4, Phi::FreeText
    phi_attr :part_5, Phi::FreeText
    phi_attr :part_6, Phi::FreeText
    phi_attr :part_7, Phi::FreeText
    phi_attr :part_8, Phi::FreeText
    phi_attr :part_9, Phi::FreeText
    phi_attr :part_10, Phi::FreeText
    phi_attr :part_11, Phi::FreeText
    phi_attr :part_12, Phi::FreeText
    phi_attr :part_13, Phi::FreeText
    phi_attr :part_14, Phi::FreeText
    phi_attr :part_15, Phi::FreeText\

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_ssms, optional: true
    has_one :patient, through: :epic_patient

    self.source_key = :NOTE_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        NOTE_ID: :id_in_source,
        PAT_ENC_CSN_ID: :encounter_id,
        ENCOUNTER_TYPE: :encounter_type,
        UPDATE_DATE: :cha_updated_at,
        USER_NAME: :staff,
        USER_PROV_TYPE: :provider_type,
        REVIEWER_NAME: :reviewer_name,
        REVIEWER_PROV_TYPE: :reviewer_provider_type,
        NOTE_TEXT_1: :part_1,
        NOTE_TEXT_2: :part_2,
        NOTE_TEXT_3: :part_3,
        NOTE_TEXT_4: :part_4,
        NOTE_TEXT_5: :part_5,
        NOTE_TEXT_6: :part_6,
        NOTE_TEXT_7: :part_7,
        NOTE_TEXT_8: :part_8,
        NOTE_TEXT_9: :part_9,
        NOTE_TEXT_10: :part_10,
        NOTE_TEXT_11: :part_11,
        NOTE_TEXT_12: :part_12,
        NOTE_TEXT_13: :part_13,
        NOTE_TEXT_14: :part_14,
        NOTE_TEXT_15: :part_15,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    scope :during_current_enrollment, -> do
      where(arel_table[:cha_updated_at].gteq(hpr_t[:enrollment_start_date])).
      joins(patient: :patient_referrals).
        merge(Health::PatientReferral.contributing)
    end

    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:cha_updated_at].to_sql} + INTERVAL '1 year'"))
            )
        )
    end

    def text
      [
        part_1,
        part_2,
        part_3,
        part_4,
        part_5,
        part_6,
        part_7,
        part_8,
        part_9,
        part_10,
        part_11,
        part_12,
        part_13,
        part_14,
        part_15,
      ].join().gsub('  ', "\n")
    end
  end
end
