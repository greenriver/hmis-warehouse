module Health
  class AgencyPatientReferral < HealthBase

    scope :claimed, -> {where(claimed: true)}
    scope :unclaimed, -> {where(claimed: false)}

    belongs_to :agency
    belongs_to :patient_referral

  end
end