module Health
  class UtilizationController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    
    def index
      @visits = @patient.visits.order(date_of_service: :desc)

      render layout: !request.xhr?
    end

  end
end