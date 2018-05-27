module Window::Health
  class CareplansController < ApplicationController
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan, only: [:show, :edit, :update, :revise]
    
    def index
      @goal = Health::Goal::Base.new
      @readonly = false
      @careplans = @patient.careplans
    end

    def show
      @goal = Health::Goal::Base.new
      @readonly = false
    end

    def edit
      @form_url = polymorphic_path(careplan_path_generator)
      @form_button = 'Save Care Plan'
    end

    def new
      Health::Careplan.transaction do
        @careplan = @patient.careplans.create!(user: current_user)
      end
      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
      # @form_url = polymorphic_path(careplans_path_generator)
      # @form_button = 'Create Care Plan'
    end

    def print
      @readonly = true
    end

    def revise
      new_id = @careplan.revise!
      flash[:notice] = "Careplan revised"
      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: new_id)
    end

    def update

      @careplan.update!(careplan_params)
      respond_with(@careplan, location: polymorphic_path(careplans_path_generator))
    end

    def self_sufficiency_assessment
      @assessment = @client.self_sufficiency_assessments.last
    end
    
    def set_careplan
      @careplan = careplan_source.where(patient_id: @patient.id).first_or_create do |cp|
        cp.user = current_user
        cp.save!
      end
    end

    def careplan_source
      Health::Careplan
    end
    
    def careplan_params
      params.require(:health_careplan).
        permit(
          :initial_date,
          :review_date,
          :patient_signed_on,
          :provider_signed_on,
          :case_manager_id,
          :responsible_team_member_id,
          :responsible_team_member_signed_on,
          :representative_id,
          :representative_signed_on,
          :provider_id,
          :provider_signed_on
        )
    end

    def flash_interpolation_options
      { resource_name: 'Care Plan' }
    end

  end
end