module HealthFlexibleServices
  class FollowUp < HealthBase
    belongs_to :patient, class_name: 'Health::Patient'
  end
end
