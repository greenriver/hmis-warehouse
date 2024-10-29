###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    belongs_to :team_nurse_care_manager, class_name: 'User', optional: true
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

    def self.available_care_coordinators
      User.active.can_manage_care_coordinators.order(last_name: :asc, first_name: :asc)
    end

    def available_care_coordinators
      User.where(id: ([team_coordinator_id] + self.class.available_care_coordinators.pluck(:id)).compact).order(last_name: :asc, first_name: :asc)
    end

    def self.available_nurse_care_managers
      User.active.nurse_care_managers.order(last_name: :asc, first_name: :asc)
    end

    def available_nurse_care_managers
      User.where(id: ([team_nurse_care_manager_id] + self.class.available_nurse_care_managers.pluck(:id)).compact).order(last_name: :asc, first_name: :asc)
    end
  end
end
