module Window::Health
  class ReleaseFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update]

    def new
      @release_form = @patient.release_forms.build(user: current_user)
      render :new
    end

    def create
      @release_form = @patient.release_forms.create(form_params)
      @release_form.save
      respond_with @release_form
    end

    def show
      render :show
    end

    def edit
      respond_with @form
    end
    
    def update
      @release_form.update(form_params)
      respond_with @release_form, location: polymorphic_path(health_path_generator)
    end

    private

    def interpolation_options
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

  end
end