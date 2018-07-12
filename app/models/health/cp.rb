module Health
  class Cp < HealthBase
    # You should only ever have one sender
    scope :sender, -> { where sender: true }

  end
end