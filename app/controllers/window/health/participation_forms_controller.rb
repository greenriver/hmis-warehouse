module Window::Health
  class ParticipationFormsController < IndividualPatientController

    include PjaxModalController
    include WindowClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]
    before_action :set_blank_form, only: [:edit, :new]
    before_action :set_health_file, only: [:update]

    def new
      # redirect to edit if there are any on-file
      if @patient.participation_forms.exists?
        @participation_form = @patient.participation_forms.recent.last
        render :edit and return
      else
        @participation_form = @patient.participation_forms.build
      end
      render :new
    end

    def create
      @participation_form = @patient.participation_forms.build(form_params)
      set_health_file
      validate_form
      @participation_form.reviewed_by = current_user if reviewed?
      @participation_form.case_manager = current_user
      @participation_form.file = @health_file if @health_file

      if ! request.xhr?
        saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).create
        save_file if @participation_form.errors.none? && saved
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @participation_form.valid?
          saved = Health::ReleaseSaver.new(form: @participation_form, user: current_user).create
          save_file if @participation_form.errors.none? && saved
        end
      end
    end

    def show
      render :show
    end

    def edit
      respond_with @participation_form
    end

    def update
      validate_form unless @participation_form.health_file.present?
      @participation_form.reviewed_by = current_user if reviewed?
      @participation_form.assign_attributes(form_params)
      @participation_form.file = @health_file if @health_file

      if ! request.xhr?
        saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
        save_file if @participation_form.errors.none? && saved
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @participation_form.valid?
          saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
          save_file if @participation_form.errors.none? && saved
        end
      end
    end

    def set_health_file
      if file = params.dig(:form, :file)
        @health_file = Health::ParticipationFormFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read,
          content_type: file.content_type
        )
      elsif @participation_form.health_file.present?
        @health_file = @participation_form.health_file
      end
    end

    def download
      @file = @participation_form.health_file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      @participation_form.health_file.destroy
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Participation Form' }
    end

    def form_params
      local_params = params.require(:form).permit(
        :signature_on,
        :reviewed_by_supervisor,
        :location
      )
      if ! current_user.can_approve_participation?
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    def set_form
      @participation_form = @patient.participation_forms.where(id: params[:id]).first
    end

    def set_blank_form
      @blank_participation_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/participation'
    end

    def save_file
      if @health_file
        @participation_form.health_file = @health_file
        @participation_form.save
      end
    end

    def validate_form
      if params.dig(:form, :file).blank? && form_params[:location].blank?
        @participation_form.errors.add :location, "Please include either a file location or upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_participation?
    end

  end
end