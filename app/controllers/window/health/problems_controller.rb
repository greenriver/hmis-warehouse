module Window::Health
  class ProblemsController < IndividualPatientController

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index]
    include PjaxModalController
    
    def index
      @problems = @patient.problems.order(onset_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end