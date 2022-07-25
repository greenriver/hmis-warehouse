###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class CoordinationTeam < HealthBase
    phi_attr :team_coordinator_id, Phi::SmallPopulation, 'ID of care coordinator for team'

    belongs_to :team_coordinator, class_name: 'User', optional: true
    validates_presence_of :team_coordinator_id
    validates_presence_of :name
  end
end
