module Health
  class UserCareCoordinator < HealthBase
    belongs_to :user
    belongs_to :care_coordinator, class_name: User.name
    validates_presence_of :user_id
    validates_presence_of :care_coordinator_id
  end
end