module HealthFlexibleService
  class FollowUp < HealthBase
    acts_as_paranoid

    belongs_to :patient, class_name: 'Health::Patient'
    belongs_to :user, class_name: 'User'
  end
end
