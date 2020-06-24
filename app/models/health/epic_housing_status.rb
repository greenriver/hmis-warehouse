###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicHousingStatus < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :collected_on, Phi::Date
    phi_attr :status, Phi::FreeText

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_housing_statuses
    has_many :patient, through: :epic_patient

    scope :within_range, -> (range) do
      where(collected_on: range)
    end

  end
end