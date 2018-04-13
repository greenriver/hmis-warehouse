module Health
  class AgencyPatientReferral < HealthBase
    enum relationship: {unknown: 0, claimed: 1, unclaimed: 2}

    belongs_to :agency
    belongs_to :patient_referral
  end
end