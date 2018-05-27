module Health
  class Service < HealthBase
    
    acts_as_paranoid

    has_many :careplans

  end
end