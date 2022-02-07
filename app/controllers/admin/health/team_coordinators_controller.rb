###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class TeamCoordinatorsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_administer_health!

    def index
      @coordinator = user_coordinator_source.new
    end

    def create
      @coordinator = user_coordinator_source.create(allowed_params)
      if @coordinator.errors.any?
        flash[:error] = @coordinator.errors.full_messages.join('; ')
        render action: :index
      else
        respond_with(@coordinator, location: admin_health_team_coordinators_path)
      end
    end

    def destroy
      @coordinator = user_coordinator_source.find(params[:id].to_i)
      @coordinator.destroy
      respond_with(@coordinator, location: admin_health_team_coordinators_path)
    end

    private def team_coordinators
      @team_coordinators ||= User.where(id: user_coordinator_source.pluck(:user_id)).index_by(&:id)
    end

    private def care_coordinators
      @care_coordinators ||= User.where(id: user_coordinator_source.pluck(:care_coordinator_id)).index_by(&:id)
    end

    private def coordinators
      @coordinators ||= begin
        coords = {}
        user_coordinator_source.all.map do |coordinator|
          team = team_coordinators[coordinator.user_id]
          coords[team] ||= []
          coords[team] << {
            care: care_coordinators[coordinator.care_coordinator_id],
            join: coordinator,
          }
        end
        coords.sort_by { |k, _| [k.last_name, k.first_name] }
      end
    end
    helper_method :coordinators

    private def user_coordinator_source
      Health::UserCareCoordinator
    end

    private def load_team_coordinator
      @team_coordinator = User.find(params[:team_coordinator_id])
    end

    private def allowed_params
      params.require(:team_coordinator).permit(
        :user_id,
        :care_coordinator_id,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Team Coordinator' }
    end
  end
end
