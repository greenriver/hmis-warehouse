###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisit < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :admit_date, Phi::Date, 'Date of admission'
    phi_attr :encounter_major_class, Phi::SmallPopulation, 'Emergency or Inpatient'

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    belongs_to :loaded_ed_ip_visit

    scope :valid, -> do
      where.not(admit_date: nil)
    end
  end
end
