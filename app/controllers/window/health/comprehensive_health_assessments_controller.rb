module Window::Health
  class ComprehensiveHealthAssessmentsController < IndividualPatientController
    include PjaxModalController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]

    def new
      @cha = @patient.chas.build
      render :new
    end

    def create
      @cha = @patient.chas.build(form_params)
      validate_form
      @cha.reviewed_by = current_user if reviewed?
      @cha.user = current_user
      save_file if @cha.errors.none? && @cha.save
      respond_with @cha, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def show
      render :show
    end

    def edit
      respond_with @cha
    end
    
    def update
      validate_form unless @cha.health_file.present?
      @cha.reviewed_by = current_user if reviewed?
      @cha.status = completed? ? :complete : :in_progress
      save_file if @cha.errors.none? && @cha.update(form_params)
      respond_with @cha, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def download
      @file = @cha.health_file
      send_data @file.content, 
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      @cha.health_file.destroy
      respond_with @cha, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Comprehensive Health Assessment' }
    end

    def form_params
      local_params = params.require(:form).permit( 
        :reviewed_by_supervisor,
        :completed
      )
      if ! current_user.can_approve_patient_items_for_agency?
        local_params.execpt(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    def set_form
      @cha = @patient.chas.where(id: params[:id]).first
    end

    def save_file
      file = params.dig(:form, :file)
      if file
        health_file = Health::ComprehensiveHealthAssessmentFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read
        )
        @cha.health_file = health_file
        @cha.save
      end
    end

    def validate_form
      if params.dig(:form, :file).blank?
        @cha.errors.add :file, "Please include a file upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_patient_items_for_agency?
    end

    def completed?
      form_params[:completed] == 'yes'
    end

  end
end