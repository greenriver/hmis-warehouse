###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Pilot
  class CareplansController < HealthController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan
    before_action :set_variable_goals, only: [:show, :print]

    def show
      @goal = Health::Goal::Base.new
      @readonly = false
    end

    def print
      @readonly = true
    end

    def update
      begin
        @careplan.update!(careplan_params)
        flash[:notice] = 'Care plan updated'
      rescue Exception => e
        flash[:error] = "Failed to update care plan. #{e}"
      end
      redirect_to action: :show
    end

    def self_sufficiency_assessment
      @assessment = @client.self_sufficiency_assessments.last
    end

    def set_careplan
      @careplan = Health::Careplan.where(patient_id: @patient.id).first_or_create do |cp|
        cp.user = current_user
        cp.save!
      end
    end

    def set_variable_goals
      @goals = @careplan.patient.epic_goals.visible
    end

    def careplan_params
      params.require(:careplan).
        permit(
          :sdh_enroll_date,
          :first_meeting_with_case_manager_date,
          :self_sufficiency_baseline_due_date,
          :self_sufficiency_final_due_date,
          :self_sufficiency_baseline_completed_date,
          :self_sufficiency_final_completed_date,
        )
    end
  end
end
