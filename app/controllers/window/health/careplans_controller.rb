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

    end
    
    def set_careplan
      @careplan = Health::Careplan.where(patient_id: @patient.id).first_or_create do |cp|
        cp.user = current_user
        cp.save!
      end
    end

  end
end