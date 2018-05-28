module Health
  class Equipment < HealthBase
    
    acts_as_paranoid

    has_many :careplans
    belongs_to :patient, required: true

  end
end