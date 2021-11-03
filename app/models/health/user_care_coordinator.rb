###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class UserCareCoordinator < HealthBase
    phi_attr :care_coordinator_id, Phi::SmallPopulation, "ID of care coordinator"

    belongs_to :user, optional: true
    belongs_to :care_coordinator, class_name: 'User', optional: true
    validates_presence_of :user_id
    validates_presence_of :care_coordinator_id
  end
end
