module HealthGoal
  extend ActiveSupport::Concern

  def new
    @goal = Health::Goal::Hpc.new
    render 'window/health/goals/new'
  end

  def create
    existing_count = @patient.hpc_goals.count
    opts = goal_params.merge({
      name: 'HPC Goal',
      number: existing_count,
      patient_id: @patient.id,
      user_id: current_user.id,
    })
    @goal = Health::Goal::Hpc.create(opts)
    if ! request.xhr?
      respond_with(@goal, location: after_path)
      return
    else
      render 'window/health/goals/create'
    end
  end

  def edit
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    render 'window/health/goals/edit'
  end

  def update
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    @goal.update(goal_params)
    if ! request.xhr?
      respond_with(@goal, location: after_path)
      return
    else
      render 'window/health/goals/update'
    end
  end

  def destroy
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    @goal.update(user_id: current_user.id)
    @goal.destroy!
    if !request.xhr?
      respond_with(@goal, location: after_path)
    else
      render 'window/health/goals/destroy'
    end
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

end