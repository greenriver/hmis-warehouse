module Window::Health
  class GoalsController < IndividualPatientController
    
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_goal, only: [:destroy, :edit, :update]

    include PjaxModalController

    def index
      @goal = Health::Goal::Hpc.new

    end

    def new
      @goal = Health::Goal::Hpc.new
    end

    def previous

    end

    def edit
    end

    def update
      @goal.update(goal_params)
      if ! request.xhr?
        respond_with(@goal, location: polymorphic_path([:edit] + careplan_path_generator, id: @careplan))
        return
      end
    end


    def create
      existing_count = @careplan.goals.count
      opts = goal_params.merge({
        name: 'HPC Goal',
        number: existing_count,
        user_id: current_user.id,
        careplan_id: @careplan.id,
      })
      @goal = Health::Goal::Hpc.create(opts)

      if ! request.xhr?
        respond_with(@goal, location: polymorphic_path([:edit] + careplan_path_generator, id: @careplan))
        return
      end
    end

    def destroy
      @goal.update(user_id: current_user.id)
      @goal.destroy!
    end

    def goal_params
      params.require(:goal).permit(
        :problem,
        :start_date,
        :goal_details,
        :intervention,
        :status,
        :responsible_team_member_id,
      )
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end
    
    private def set_goal
      @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    end

    def flash_interpolation_options
      { resource_name: 'Goal' }
    end
  end
end