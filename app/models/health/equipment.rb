module Health
  class Equipment < HealthBase
    
    acts_as_paranoid

    has_many :careplans

  end
end