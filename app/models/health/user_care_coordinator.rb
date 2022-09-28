###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class UserCareCoordinator < HealthBase
    phi_attr :care_coordinator_id, Phi::SmallPopulation, 'ID of care coordinator'
    phi_attr :coordination_team_id, Phi::SmallPopulation, 'ID of care coordination team'

    belongs_to :user, optional: true
    belongs_to :care_coordinator, class_name: 'User', optional: true # TODO: Obsolete, to be removed
    belongs_to :coordination_team, optional: true, inverse_of: :user_care_coordinators

    validates_presence_of :user_id

    # patients with CC or NCM relationship to this user
    def patients
      user&.patients
    end

    # patients with CC relationship to this user
    def care_coordination_patients
      user&.care_coordination_patients
    end
  end
end
