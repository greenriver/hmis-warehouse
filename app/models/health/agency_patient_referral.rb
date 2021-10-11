###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class AgencyPatientReferral < HealthBase
    acts_as_paranoid

    phi_attr :patient_referral_id, Phi::OtherIdentifier, "ID of patient referral"

    scope :claimed, -> {where(claimed: true)}
    scope :unclaimed, -> {where(claimed: false)}

    belongs_to :agency, optional: true
    belongs_to :patient_referral, optional: true

  end
end
