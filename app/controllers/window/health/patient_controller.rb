module Window::Health
  class PatientController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index, :update]
    include PjaxModalController
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index      
      load_patient_metrics
      render layout: !request.xhr?      
    end

    def update
      @patient.update(patient_params)
      if request.xhr?
        head :ok and return
      else
        respond_with(@patient, location: health_patients_path())
      end
    end

    def patient_params
      params.require(:patient).permit(
        :care_coordinator_id
      )
    end

    def flash_interpolation_options
      { resource_name: 'Patient' }
    end
    
  end
end