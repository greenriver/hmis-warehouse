module Window::Health
  class MedicationsController < IndividualPatientController

    before_action :set_client, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      set_hpc_patient
      if @patient.blank?
        set_patient
      end
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end