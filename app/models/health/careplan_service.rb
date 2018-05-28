module Health
  class CareplanService < HealthBase
    
    acts_as_paranoid

    belongs_to :careplans, class_name: Health::Careplan.name
    belongs_to :services, class_name: Health::Service.name

  end
end