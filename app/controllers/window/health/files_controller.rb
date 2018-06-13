module Window::Health
  class FilesController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      @files = @patient.health_files
    end

    def show
      @file = @patient.health_files.find(params[:id].to_i)
      send_data @file.content, 
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end
  end
end