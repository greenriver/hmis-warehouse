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