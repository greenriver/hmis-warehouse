module Window::Health
  class ProblemsController < IndividualPatientController

    before_action :set_client, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      set_hpc_patient
      if @patient.blank?
        set_patient
      end
      @problems = @patient.problems.order(onset_date: :desc)
      
      render layout: !request.xhr?
    end

  end
end