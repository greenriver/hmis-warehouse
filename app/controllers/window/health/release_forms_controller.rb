module Window::Health
  class ReleaseFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]

    def new
      @release_form = @patient.release_forms.build(user: current_user)
      render :new
    end

    def create
      @release_form = @patient.release_forms.build(form_params)
      validate_form
      save_file if @release_form.errors.none? && @release_form.save
      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def show
      render :show
    end

    def edit
      respond_with @release_form
    end
    
    def update
      validate_form unless @release_form.health_file.present?
      save_file if @release_form.errors.none? && @release_form.update(form_params)
      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def download
      @file = @release_form.health_file
      send_data @file.content, 
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      @release_form.health_file.destroy
      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Release Form' }
    end

    def form_params
      params.require(:form).permit( 
        :signature_on,
        :file_location,
        :supervisor_reviewed
      )
    end

    def set_form
      @release_form = @patient.release_forms.where(id: params[:id]).first
    end

    def save_file
      file = params.dig(:form, :file)
      if file
        health_file = Health::ReleaseFormFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read
        )
        @release_form.health_file = health_file
        @release_form.save
      end
    end

    def validate_form
      if params.dig(:form, :file).blank? && form_params[:file_location].blank?
        @release_form.errors.add :file_location, "Please include either a file location or upload."
      end
    end

  end
end