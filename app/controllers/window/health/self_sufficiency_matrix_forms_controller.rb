module Window::Health
  class SelfSufficiencyMatrixFormsController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_form, only: [:show, :edit, :update]

    def new
      @form = @patient.self_sufficiency_matrix_forms.build(user: current_user)
      @form.save(validate: false)
      redirect_to polymorphic_path([:edit] + self_sufficiency_matrix_form_path_generator, id: @form.id)
    end

    def show
      render :show
    end

    def edit
      respond_with @form
    end
    
    def update
      if params[:commit]=='Save'
        @form.completed_at = Time.current
      end
      @form.update(form_params)
      respond_with @form, location: polymorphic_path(careplans_path_generator)
    end

    private

    def form_params
      params.require(:form).permit( 
        :point_completed,
        :housing_score,
        :housing_notes,
        :income_score,
        :income_notes,
        :benefits_score,
        :benefits_notes,
        :disabilities_score,
        :disabilities_notes,
        :food_score,
        :food_notes,
        :employment_score,
        :employment_notes,
        :education_score,
        :education_notes,
        :mobility_score,
        :mobility_notes,
        :life_score,
        :life_notes,
        :healthcare_score,
        :healthcare_notes,
        :physical_health_score,
        :physical_health_notes,
        :mental_health_score,
        :mental_health_notes,
        :substance_abuse_score,
        :substance_abuse_notes,
        :criminal_score,
        :criminal_notes,
        :legal_score,
        :legal_notes,
        :safety_score,
        :safety_notes,
        :risk_score,
        :risk_notes,
        :family_score,
        :family_notes,
        :community_score,
        :community_notes,
        :time_score,
        :time_notes,
        :collection_location
      )
    end

    def set_form
      @form = @patient.self_sufficiency_matrix_forms.where(id: params[:id]).first
    end

  end
end