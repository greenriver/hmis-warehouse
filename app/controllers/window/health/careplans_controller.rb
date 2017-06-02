module Window::Health
  class CareplansController < ApplicationController
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan
    
    def show
      @goal = Health::Goal::Base.new
      @goals = @careplan.goals.order(number: :asc)
    end

    def update
      begin
        @careplan.update!(careplan_params)
        flash[:notice] = "Careplan updated"
      rescue Exception => e
        flash[:error] = "Failed to update careplan. #{e}"
      end
      redirect_to action: :show
    end
    
    def set_careplan
      @careplan = Health::Careplan.where(patient_id: @patient.id).first_or_create do |cp|
        cp.user = current_user
        cp.save!
      end
    end

    def careplan_params
      params.require(:careplan).
        permit(
          :sdh_enroll_date,
          :first_meeting_with_case_manager_date,
          :self_sufficiency_baseline_due_date,
          :self_sufficiency_final_due_date,
          :self_sufficiency_baseline_completed_date,
          :self_sufficiency_final_completed_date
        )
    end

  end
end