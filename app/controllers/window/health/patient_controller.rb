module Window::Health
  class PatientController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index]
    include PjaxModalController

    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index
      load_patient_metrics
      render layout: !request.xhr?      
    end
    
  end
end