module Window::Health
  class AppointmentsController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    
    def index
      @appointments = @patient.appointments.order(appointment_time: :desc)

      render layout: !request.xhr?
    end

  end
end