module Window::Health
  class ReleaseFormsController < IndividualPatientController

    include PjaxModalController
    include WindowClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]
    before_action :set_blank_form, only: [:new, :edit]

    def new
      # redirect to edit if there are any on-file
      if @patient.release_forms.exists?
        @release_form = @patient.release_forms.recent.last
        render :edit and return
      else
        @release_form = @patient.release_forms.build
      end
      render :new
    end

    def create
      @release_form = @patient.release_forms.build(form_params)
      if @release_form.health_file.present?
        @release_form.health_file.set_calculated!(current_user.id, @client.id)
      end
      validate_form
      @release_form.reviewed_by = current_user if reviewed?
      @release_form.user = current_user

      if ! request.xhr?
        saved = Health::ReleaseSaver.new(form: @release_form, user: current_user).create
        respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @release_form.valid?
          saved = Health::ReleaseSaver.new(form: @release_form, user: current_user).create
        end
      end
    end

    def show
      render :show
    end

    def edit
      respond_with @release_form
    end

    def update
      validate_form unless @release_form.health_file.present?
      @release_form.reviewed_by = current_user if reviewed?
      @release_form.assign_attributes(form_params)
      
      if @release_form.health_file&.new_record?
        @release_form.health_file.set_calculated!(current_user.id, @client.id)
      end
      if ! request.xhr?
        saved = Health::ReleaseSaver.new(form: @release_form, user: current_user).update
        respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      else
        if @release_form.valid?
          saved = Health::ReleaseSaver.new(form: @release_form, user: current_user).update
        end
      end
    end

    def download
      @file = @release_form.health_file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      if @release_form.health_file.present?
        @release_form.health_file.destroy
      end
      @release_form.build_health_file
      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Release Form' }
    end

    def form_params
      local_params = params.require(:form).permit(
        :signature_on,
        :file_location,
        :reviewed_by_supervisor,
        health_file_attributes: [
          :id,
          :file,
          :file_cache
        ]
      )
      if ! current_user.can_approve_release?
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    def set_form
      @release_form = @patient.release_forms.where(id: params[:id]).first
    end

    def set_blank_form
      @blank_release_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/release'
    end

    def form_url(opts={})
      if @release_form.new_record?
        polymorphic_path(release_forms_path_generator, client_id: @client.id)
      else
        polymorphic_path(release_form_path_generator, client_id: @client.id, id: @release_form.id)
      end
    end
    helper_method :form_url

    def health_file_params_blank?
      attrs = form_params[:health_file_attributes] || {}
      attrs[:file].blank? && attrs[:file_cache].blank?
    end

    def validate_form
      if health_file_params_blank? && form_params[:file_location].blank?
        @release_form.errors.add :file_location, "Please include either a file location or upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_release?
    end

  end
end