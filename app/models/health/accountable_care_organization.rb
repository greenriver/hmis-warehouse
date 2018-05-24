module Health
  class AccountableCareOrganization < HealthBase

    validates_presence_of :name

    has_many :patient_referrals

  end
end