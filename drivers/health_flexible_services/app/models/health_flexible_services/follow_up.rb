module HealthFlexibleServices
  class FollowUp < HealthBase
    belongs_to :patient, class_name: 'Health::Patient'
    belongs_to :user, class_name: 'User'
  end
end
