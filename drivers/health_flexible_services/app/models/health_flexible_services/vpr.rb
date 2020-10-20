module HealthFlexibleServices
  class Vpr < HealthBase
    belongs_to :patient, class_name: 'Health::Patient'
  end
end
