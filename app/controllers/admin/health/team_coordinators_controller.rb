module Admin::Health
  class TeamCoordinatorsController < HealthController
    before_action :require_has_administartive_access_to_health!
    before_action :require_can_administer_health!
    before_action :load_team_coordinators, only: [:index, :create]
    before_action :load_care_coordinators, only: [:index, :create]
    before_action :load_coordinators, only: [:index, :create]

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

    private

    def load_team_coordinators
      @team_coordinators = User.where(id: user_coordinator_source.pluck(:user_id)).index_by(&:id)
    end

    def load_care_coordinators
      @care_coordinators = User.where(id: user_coordinator_source.pluck(:care_coordinator_id)).index_by(&:id)
    end

    def load_coordinators
      @coordinators = user_coordinator_source.all
    end

    def user_coordinator_source
      Health::UserCareCoordinator
    end

    def load_team_coordinator
      @team_coordinator = User.find(params[:team_coordinator_id])
    end

    def allowed_params
      params.require(:team_coordinator).permit(
        :user_id,
        :care_coordinator_id
      )
    end

    def flash_interpolation_options
      { resource_name: 'Team Coordinator' }
    end
  end  
end