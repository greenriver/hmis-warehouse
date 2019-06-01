###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class AgencyPatientReferral < HealthBase
    phi_attr :patient_referral_id, Phi::OtherIdentifier

    scope :claimed, -> {where(claimed: true)}
    scope :unclaimed, -> {where(claimed: false)}

    belongs_to :agency
    belongs_to :patient_referral

  end
end