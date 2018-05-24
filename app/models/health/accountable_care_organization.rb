module Health
  class AccountableCareOrganization < HealthBase

    validates_presence_of :name

  end
end