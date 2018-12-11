# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class AccountableCareOrganization < HealthBase

    validates_presence_of :name

    has_many :patient_referrals

    scope :active, -> { where active: true }

  end
end