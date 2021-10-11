###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicHousingStatus < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, "ID of housing status"
    phi_attr :collected_on, Phi::Date, "Date of collection"
    phi_attr :status, Phi::FreeText, "Description of housing status"

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_housing_statuses, optional: true
    has_many :patient, through: :epic_patient

    scope :within_range, -> (range) do
      where(collected_on: range)
    end

  end
end
