module Health
  class DataSource < Base

    has_many :patients
    has_many :medications
    has_many :problems
    has_many :appointments
    has_many :visits
    has_many :epic_goals
    
  end
end
