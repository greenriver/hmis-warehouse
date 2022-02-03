###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Problem < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :onset_date, Phi::Date
    phi_attr :last_assessed, Phi::Date
    phi_attr :name, Phi::FreeText
    phi_attr :comment, Phi::FreeText
    phi_attr :icd10_list, Phi::SmallPopulation
    phi_attr :id_in_source, Phi::OtherIdentifier

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :problems, optional: true

    self.source_key = :PL_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        PL_ID: :id_in_source,
        name: :name,
        comment: :comment,
        icd10_list: :icd10_list,
        last_assessed: :last_assessed,
        onset_date: :onset_date,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
