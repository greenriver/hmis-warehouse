module Window::Health
  class MedicationsController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index]
    include PjaxModalController

    def index
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end