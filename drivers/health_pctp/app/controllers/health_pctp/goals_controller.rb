###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class GoalsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_goal, only: [:edit, :update, :destroy]

    def index
    end

    def new
      @modal_size = :xxl
      @goal = @careplan.care_goal_details.build
    end

    def create
      @goal = @careplan.care_goal_details.create(goals_params)
    end

    def edit
      @modal_size = :xxl
    end

    def update
      @goal.update(goals_params)
    end

    def destroy
      @goal.destroy
    end

    private def goals_params
      params.require(:health_pctp_care_goal).permit(
        :domain,
        :goal,
        :status,
        :estimated_completion_date,
        :start_date,
        :end_date,
        :barriers,
        :followup,
        :comments,
        :source,
        :priority,
        :plan,
        :responsible_party,
        :times,
        :interval,
      )
    end

    private def set_careplan
      @careplan = @patient.pctps.find(params[:careplan_id])
    end

    private def set_goal
      @goal = @careplan.care_goal_details.find(params[:id])
    end
  end
end
