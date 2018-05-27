module Health
  class CareplanService < HealthBase
    
    acts_as_paranoid

    belongs_to :careplans
    belongs_to :services

  end
end