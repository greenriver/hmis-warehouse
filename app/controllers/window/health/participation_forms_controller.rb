module Window::Health
  class ParticipationFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update]

    def new
      @participation_form = @patient.participation_forms.build(case_manager: current_user)
      render :new
    end

    def create
      @participation_form = @patient.participation_forms.create(form_params)
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
      @participation_form.update(form_params)
      respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
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
        :location,
        :file
      )
    end

    def set_form
      @participation_form = @patient.participation_forms.where(id: params[:id]).first
    end

  end
end