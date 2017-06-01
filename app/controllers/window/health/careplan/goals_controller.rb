module Window::Health::Careplan
  class GoalsController < ApplicationController
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan

    
    def create
        raise params.inspect
    end

    def update

    end

    def goal_params
      params.require(:goal).
        permit(
            :name
        )
    end

    def set_careplan
      @careplan = @patient.careplan
    end

  end
end