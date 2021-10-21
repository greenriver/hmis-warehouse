###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Visit < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :department, Phi::SmallPopulation
    phi_attr :date_of_service, Phi::Date
    phi_attr :id_in_source, Phi::OtherIdentifier

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :visits, optional: true

    self.source_key = :ENC_ID

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        PAT_ID: :patient_id,
        ENC_ID: :id_in_source,
        date_of_service: :date_of_service,
        department: :department,
        type: :visit_type,
        provider: :provider,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
