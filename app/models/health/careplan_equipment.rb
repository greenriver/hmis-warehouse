module Health
  class CareplanEquipment < HealthBase
    
    acts_as_paranoid

    belongs_to :careplans
    belongs_to :equipments

  end
end