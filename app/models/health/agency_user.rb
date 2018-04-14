module Health
  class AgencyUser < HealthBase

    belongs_to :agency
    belongs_to :user
    
  end
end