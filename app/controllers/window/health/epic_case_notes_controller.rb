module Window::Health
  class EpicCaseNotesController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient

    include PjaxModalController
    include WindowClientPathGenerator

    def show
      @note = @patient.epic_case_notes.find(params[:id].to_i)
    end


  end
end