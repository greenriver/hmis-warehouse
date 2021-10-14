###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Medication < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, "ID of medication"
    phi_attr :start_date, Phi::Date, "Start date of medication"
    phi_attr :ordered_date, Phi::Date, "Ordered date of medication"
    phi_attr :name, Phi::NeedsReview, "Name of medication"
    phi_attr :instructions, Phi::FreeText, "Medication's instructions"
    phi_attr :id_in_source, Phi::OtherIdentifier

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :medications, optional: true

    self.source_key = :OM_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        OM_ID: :id_in_source,
        name: :name,
        start_date: :start_date,
        ordered_date: :ordered_date,
        instructions: :instructions,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
