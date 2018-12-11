# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class UserCareCoordinator < HealthBase
    phi_attr :care_coordinator_id, Phi::SmallPopulation

    belongs_to :user
    belongs_to :care_coordinator, class_name: User.name
    validates_presence_of :user_id
    validates_presence_of :care_coordinator_id
  end
end