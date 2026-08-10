###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class TeamPerformance
    include ArelHelper

    def initialize(range:, team_scope: nil)
      @range = (range.first.to_date..range.last.to_date)
      @team_scope = team_scope
    end

    # Lightweight team list for the Team Patients index page.
    # Avoids triggering full performance computations (e.g., claims lookups).
    def teams_for_picker
      # Keep parity with the historical UI behavior: the team picker is keyed by team name
      # (params[:entity_id]) and should not show duplicate names.
      team_scope.select(:name).distinct.order(name: :asc)
    end

    # Patient ids for a single team within the report range.
    # This is used to build the patient list without running full performance counts.
    def patient_ids_for_team(team)
      return [] unless team.present?

      patient_ids_for_care_coordinator_ids(
        Health::UserCareCoordinator.where(coordination_team_id: team.id).select(:user_id),
      )
    end

    # Patient ids across all teams in the report scope within the report range.
    def patient_ids_for_all_teams
      patient_ids_for_care_coordinator_ids(
        Health::UserCareCoordinator.where(coordination_team_id: team_scope.select(:id)).select(:user_id),
      )
    end

    def team_scope
      @team_scope || Health::CoordinationTeam.all
    end

    private def patient_ids_for_care_coordinator_ids(care_coordinator_ids)
      return [] unless care_coordinator_ids.exists?

      Health::Patient.
        joins(:patient_referral).
        merge(Health::PatientReferral.active_within_range(start_date: @range.first, end_date: @range.last)).
        where(care_coordinator_id: care_coordinator_ids).
        distinct.
        pluck(:id)
    end
  end
end
