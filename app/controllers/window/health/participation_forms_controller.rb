module Window::Health
  class ParticipationFormsController < IndividualPatientController

    include PjaxModalController
    include WindowClientPathGenerator
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]
    before_action :set_blank_form, only: [:edit, :new, :remove_file]
    before_action :set_upload_object, only: [:edit, :update, :download, :remove_file]
    
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
      set_upload_object
      if @participation_form.health_file.present?
        @participation_form.health_file.set_calculated!(current_user.id, @client.id)
      end
      validate_form
      @participation_form.reviewed_by = current_user if reviewed?
      @participation_form.case_manager = current_user

      if ! request.xhr?
        saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).create
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @participation_form.valid?
          saved = Health::ReleaseSaver.new(form: @participation_form, user: current_user).create
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
      if @participation_form.health_file&.new_record?
        @participation_form.health_file.set_calculated!(current_user.id, @client.id)
      end
      if ! request.xhr?
        saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @participation_form.valid?
          saved = Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
        end
      end
    end

    # def download
    #   @file = @participation_form.health_file
    #   send_data @file.content,
    #     type: @file.content_type,
    #     filename: File.basename(@file.file.to_s)
    # end

    # def remove_file
    #   if @participation_form.health_file.present?
    #     @participation_form.health_file.destroy
    #   end
    #   @participation_form.build_health_file
    #   respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    # end

    private

    def flash_interpolation_options
      { resource_name: 'Participation Form' }
    end

    def form_params
      local_params = params.require(:form).permit(
        :signature_on,
        :reviewed_by_supervisor,
        :location,
        health_file_attributes: [
          :id,
          :file,
          :file_cache
        ]
      )
      if ! current_user.can_approve_participation?
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    def set_upload_object
      @upload_object = @participation_form
      if action_name == 'remove_file'
        @location = polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      end
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + participation_form_path_generator, client_id: @client.id, id: @participation_form.id ) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : {confirm: 'Form errors must be fixed before you can download this file.'}
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + participation_form_path_generator, client_id: @client.id, id: @participation_form.id ) : '#'
    end

    def set_form
      @participation_form = @patient.participation_forms.where(id: params[:id]).first
    end

    def set_blank_form
      @blank_participation_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/participation'
    end

    def form_url(opts={})
      if @participation_form.new_record?
        polymorphic_path(participation_forms_path_generator, client_id: @client.id)
      else
        polymorphic_path(participation_form_path_generator, client_id: @client.id, id: @participation_form.id)
      end
    end
    helper_method :form_url

    def health_file_params_blank?
      attrs = form_params[:health_file_attributes] || {}
      attrs[:file].blank? && attrs[:file_cache].blank?
    end

    def validate_form
      if health_file_params_blank? && form_params[:location].blank?
        @participation_form.errors.add :location, "Please include either a file location or upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_participation?
    end

  end
end