module Window::Health
  class UtilizationController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index]
    include PjaxModalController
    
    def index
      @visits = @patient.visits.order(date_of_service: :desc)

      render layout: !request.xhr?
    end
  end
end