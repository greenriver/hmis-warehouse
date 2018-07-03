module Window::Health
  class ComprehensiveHealthAssessmentsController < IndividualPatientController
    helper ChaHelper

    include PjaxModalController
    include WindowClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file, :upload]
    before_action :set_locked, only: [:show, :edit]
    before_action :set_health_file, only: [:upload, :update]

    def new
      # redirect to edit if there are any incomplete
      if @patient.chas.incomplete.exists?
        @cha = @patient.chas.incomplete.recent.last
      else
        @cha = @patient.chas.build(user: current_user)
        Health::ChaSaver.new(cha: @cha, user: current_user).create
      end
      redirect_to polymorphic_path([:edit] + cha_path_generator, id: @cha.id)
    end

    def update
      @tt = form_params
      @cha.assign_attributes(form_params)
      @cha.file = @health_file if @health_file
      Health::ChaSaver.new(cha: @cha, user: current_user, complete: completed?, reviewed: reviewed?).update
      respond_with @cha, location: polymorphic_path(careplans_path_generator)
    end

    def edit
      if @cha_locked
        flash.notice = _('This CHA has already been reviewed, or a claim was submitted; it is no longer editable')
        redirect_to polymorphic_path(cha_path_generator, id: @cha.id) and return
      end
      # For errors in new/edit forms
      @service = Health::Service.new
      @equipment = Health::Equipment.new
      @services = @patient.services.order(date_requested: :desc)
      @equipments = @patient.equipments
      @blank_cha_url = GrdaWarehouse::PublicFile.url_for_location 'patient/cha'

      respond_with @cha
    end

    def upload
      @cha.file = @health_file if @health_file
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
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    def set_locked
      @cha_locked = @cha.reviewed_by || @cha.qualifying_activities.submitted.exists?
    end

    def set_form
      @cha = @patient.chas.where(id: params[:id]).first
    end

    def set_health_file
      if file = params.dig(:form, :file)
        @health_file = Health::ComprehensiveHealthAssessmentFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read,
          content_type: file.content_type
        )
      elsif @cha.health_file.present?
        @health_file = @cha.health_file
      end
    end

    def save_file
      if @health_file
        @cha.health_file = @health_file
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
      form_params[:completed] == 'yes' || form_params[:completed] == '1'
    end

  end
end