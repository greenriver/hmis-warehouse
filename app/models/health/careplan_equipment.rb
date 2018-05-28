module Health
  class CareplanEquipment < HealthBase
    
    acts_as_paranoid

    belongs_to :careplans, class_name: Health::Careplan.name
    belongs_to :equipments, class_name: Health::Equipment.name

  end
end