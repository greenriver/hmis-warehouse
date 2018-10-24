module Window::Health
  class EpicCaseNotesController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient

    include PjaxModalController
    include WindowClientPathGenerator

    def show
      @note = @patient.epic_case_notes.find(params[:id].to_i)
    end

    protected def title_for_show
      "#{@client.name} - Health - Epic Case Note"
    end

  end
end