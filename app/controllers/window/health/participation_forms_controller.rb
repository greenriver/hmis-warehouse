module Window::Health
  class ParticipationFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update, :download]

    def new
      @participation_form = @patient.participation_forms.build(case_manager: current_user)
      render :new
    end

    def create
      @participation_form = @patient.participation_forms.build(form_params)
      validate_form
      save_file if @participation_form.errors.none? && 
      @participation_form.save
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def show
      render :show
    end

    def edit
      respond_with @form
    end
    
    def update
      validate_form
      @participation_form.update(form_params)
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def download
      @file = @participation_form.health_file
      send_data @file.content, 
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    private

    def flash_interpolation_options
      { resource_name: 'Participation Form' }
    end

    def form_params
      params.require(:form).permit( 
        :signature_on,
        :case_manager_id,
        :reviewed_by_id,
        :location
      )
    end

    def set_form
      @participation_form = @patient.participation_forms.where(id: params[:id]).first
    end

    def save_file
      file = params.dig(:form, :file)
      if file
        health_file = Health::ParticipationFormFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read
        )
        @participation_form.health_file = health_file
        @participation_form.save
      end
    end

    def validate_form
      if params.dig(:form, :file).present? && form_params[:location].present?
        @participation_form.errors.add :location, "Please provide either a file location or file upload, but not both."
      elsif params.dig(:form, :file).blank? && form_params[:location].blank?
        @participation_form.errors.add :location, "Please include either a file location or upload."
      end
    end

  end
end