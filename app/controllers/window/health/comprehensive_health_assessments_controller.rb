module Window::Health
  class ComprehensiveHealthAssessmentsController < IndividualPatientController
    helper ChaHelper

    include PjaxModalController
    include WindowClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file, :upload]

    def new
      @cha = @patient.chas.build(user: current_user)
      @cha.save(validate: false)
      redirect_to polymorphic_path([:edit] + cha_path_generator, id: @cha.id)
    end

    def update
      if params[:commit]=='Save'
        @cha.completed_at = Time.current
      end
      @cha.reviewed_by = current_user if reviewed?
      @cha.update(form_params)
      respond_with @cha, location: polymorphic_path(careplans_path_generator)
    end

    def edit
      respond_with @cha
    end
    
    def upload
      validate_form
      save_file if @cha.errors.none? && @cha.update(form_params)
      respond_with @cha, location: polymorphic_path([:edit] + cha_path_generator, id: @cha.id)
    end

    def show
      render :show
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
        :completed,
        *Health::ComprehensiveHealthAssessment::PERMITTED_PARAMS
      )
      if ! current_user.can_approve_cha?
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
        @cha.errors.add :file, "Please select a file to upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_cha?
    end

    def completed?
      form_params[:completed] == 'yes'
    end

  end
end