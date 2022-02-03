###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthGoal
  extend ActiveSupport::Concern

  def new
    @goal = Health::Goal::Hpc.new
    render 'health/goals/new'
  end

  def create
    existing_count = @patient.hpc_goals.count
    opts = goal_params.merge(
      name: 'HPC Goal',
      number: existing_count,
      patient_id: @patient.id,
      user_id: current_user.id,
    )
    @goal = Health::Goal::Hpc.create(opts)
    if ! request.xhr?
      respond_with(@goal, location: after_path)
      nil
    else
      render 'health/goals/create'
    end
  end

  def edit
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    render 'health/goals/edit'
  end

  def update
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    @goal.update(goal_params)
    if ! request.xhr?
      respond_with(@goal, location: after_path)
      nil
    else
      render 'health/goals/update'
    end
  end

  def destroy
    @goal = ::Health::Goal::Hpc.find(params[:id].to_i)
    @goal.update(user_id: current_user.id)
    @goal.destroy!
    if !request.xhr?
      respond_with(@goal, location: after_path)
    else
      render 'health/goals/destroy'
    end
  end

  def goal_params
    params.require(:goal).permit(
      :problem,
      :start_date,
      :goal_details,
      :intervention,
      :timeframe,
      :status,
      :action_step_0,
      :action_step_1,
      :action_step_2,
      :action_step_3,
      :action_step_4,
      :action_step_5,
      :action_step_6,
      :action_step_7,
      :action_step_8,
      :action_step_9,
      :timeframe_0,
      :timeframe_1,
      :timeframe_2,
      :timeframe_3,
      :timeframe_4,
      :timeframe_5,
      :timeframe_6,
      :timeframe_7,
      :timeframe_8,
      :timeframe_9,
      :responsible_team_member_id,
    )
  end
end
