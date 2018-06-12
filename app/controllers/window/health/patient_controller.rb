module Window::Health
  class PatientController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index      
      load_patient_metrics
      render layout: !request.xhr?      
    end

    def update
      raise patient_params.inspect
    end

    def patient_params
      require(:patient).permit(
        :care_coordinator_id
      )
    end
    
  end
end