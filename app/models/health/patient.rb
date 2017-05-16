module Health
  class Patient < HealthBase

    has_many :appointments
    has_many :medications
    has_many :problems
    has_many :visits

  end
end
