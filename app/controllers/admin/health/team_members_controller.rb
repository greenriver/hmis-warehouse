###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class TeamMembersController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_administer_health!
    before_action :set_team_members

    def index
    end

    def create
      team_member = Health::UserCareCoordinator.create(team_member_params)
      flash[:error] = team_member.errors.full_messages.join('; ') if team_member.errors.any?
      render action: :index
    end

    def destroy
      team_member = Health::UserCareCoordinator.find(params[:id])
      team_member.destroy
      flash[:error] = team_member.errors.full_messages.join('; ') if team_member.errors.any?
      render action: :index
    end

    private def set_team_members
      @team_members = Health::UserCareCoordinator.
        joins(:coordination_team).
        order(:coordination_team_id).
        preload(:coordination_team, :user)
    end

    private def team_member_params
      params.require(:team_member).permit(
        :user_id,
        :coordination_team_id,
      )
    end
  end
end
