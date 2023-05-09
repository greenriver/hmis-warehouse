###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    has_many :user_care_coordinators, inverse_of: :coordination_team

    validates_presence_of :team_coordinator_id
    validates_presence_of :name

    scope :lead_by, ->(user_id) do
      where(team_coordinator_id: user_id)
    end

    # A Patient is included in the team if their Care Coordinator is assigned to this team.
    def patients
      user_care_coordinators&.
        map(&:care_coordination_patients)&.
        reduce(&:or) ||
        Health::Patient.none
    end
  end
end
