module Window::Health
  class ParticipationFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]

    def new
      @participation_form = @patient.participation_forms.build
      render :new
    end

    def create
      @participation_form = @patient.participation_forms.build(form_params)
      validate_form
      @participation_form.case_manager = current_user
      save_file if @participation_form.errors.none? && 
      @participation_form.save
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
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
      save_file if @participation_form.errors.none? && @participation_form.update(form_params)
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
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
      params.require(:form).permit( 
        :signature_on,
        :reviewed_by_supervisor,
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
      if params.dig(:form, :file).blank? && form_params[:location].blank?
        @participation_form.errors.add :location, "Please include either a file location or upload."
      end
    end

    def reviewed?
      form_params[:reviewed_by_supervisor]=='yes'
    end

  end
end