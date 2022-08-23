###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class CoordinationTeamsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_administer_health!
    before_action :set_teams

    def index
    end

    def create
      team = team_class.create(team_params)
      flash[:error] = team.errors.full_messages.join('; ') if team.errors.any?
      respond_with(team, location: admin_health_coordination_teams_path)
    end

    def update
      team = team_class.find(params[:id].to_i)
      team.update(team_params)
      flash[:error] = team.errors.full_messages.join('; ') if team.errors.any?
      respond_with(team, location: admin_health_coordination_teams_path)
    end

    def destroy
      team = team_class.find(params[:id].to_i)
      team.destroy
      flash[:error] = team.errors.full_messages.join('; ') if team.errors.any?
      respond_with(team, location: admin_health_coordination_teams_path)
    end

    private def team_params
      params.require(:health_coordination_team).permit(
        :name,
        :team_coordinator_id,
        :team_nurse_care_manager_id,
      )
    end

    private def set_teams
      @teams = team_class.order(name: :asc)
    end

    private def team_class
      Health::CoordinationTeam
    end

    def flash_interpolation_options
      { resource_name: 'Care Coordination Team' }
    end
  end
end
