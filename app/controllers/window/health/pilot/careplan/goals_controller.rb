module Window::Health::Careplan
  class GoalsController < IndividualPatientController
    include PjaxModalController    
    include WindowClientPathGenerator
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan
    before_action :set_goal, only: [:update, :destroy, :show, :previous]

    
    def new
      @goal = Health::Goal::Base.new()
    end

    def show

    end

    def previous

    end

    def sort
      order = params[:order].reject(&:blank?).map(&:to_i)
      order.each_with_index do |id, index|
        begin
          Health::Goal::Base.transaction do
            goal = Health::Goal::Base.find(id)
            goal.update!(number: index + 1)
          end
        rescue Exception => e
          render json: {error: "Unable to update order. #{e}", params: order}
          return
        end
      end
      render json: {success: 'Goal order updated, refresh to see changes.', params: order}
    end

    def create
      type = goal_params[:type]
      @goal = Health::Goal::Base.new(goal_params)
      klass = type.constantize if Health::Goal::Base.available_types.map(&:to_s).include?(type)
      opts = goal_params.merge({
        careplan_id: @careplan.id, 
        number: Health::Goal::Base.next_available_number(careplan_id: @careplan.id),
        user_id: current_user.id
      })
      begin
        raise 'Member type not found' unless klass.present?
        new_goal = klass.create!(opts)
        flash[:notice] = "Added #{new_goal.type_name}"
      rescue Exception => e
        @goal.validate
        flash[:error] = "Failed to add goal #{e}"
      end
      redirect_to create_success_path      
    end

    def update
      begin
        @goal.update!(goal_params.merge({user_id: current_user.id}))
        flash[:notice] = "#{@goal.name} updated"
      rescue Exception => e
        flash[:error] = "Failed to update goal #{e}"
      end

      respond_to do |format|
        format.js do
          render action: :show
        end
        format.html do
          redirect_to create_success_path
        end
      end
    end

    def destroy
      begin
        @goal.destroy!
        flash[:notice] = "Goal \"#{@goal.name}\" deleted"
      rescue Exception => e
        flash[:error] = "Failed to delete goal #{e}"
      end
      redirect_to create_success_path
    end

    def create_success_path 
      window_client_health_careplan_path(client_id: @client.id)
    end

    def goal_params
      params.require(:goal).
        permit(
          :name,
          :type,
          :number,
          :name,
          :associated_dx,
          :barriers,
          :provider_plan,
          :case_manager_plan,
          :rn_plan,
          :bh_plan,
          :other_plan,
          :confidence,
          :az_housing,
          :az_income,
          :az_non_cash_benefits,
          :az_disabilities,
          :az_food,
          :az_employment,
          :az_training,
          :az_transportation,
          :az_life_skills,
          :az_health_care_coverage,
          :az_physical_health,
          :az_mental_health,
          :az_substance_use,
          :az_criminal_justice,
          :az_legal,
          :az_safety,
          :az_risk,
          :az_family,
          :az_community,
          :az_time_management,
        )
    end

    def set_careplan
      @careplan = @patient.careplan
    end

    def set_goal
      @goal = Health::Goal::Base.find(params[:id].to_i)
    end

  end
end