module Window::Health
  class MedicationsController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    
    def index
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end