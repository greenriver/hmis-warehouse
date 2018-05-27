module Window::Health
  class ServicesController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    def index
      # For errors in new/edit forms
      @service = Health::Service.new
      @equipment = Health::Equipment.new
    end

    def new
      @service = Health::Service.new
      @equipment = Health::Equipment.new
    end

  
    def create
      
    end

    def destroy
      
    end

    def service_params
      params.require(:service).permit(
        :service_type,
        :provider,
        :hours,
        :days,
        :date_requested,
        :effective_date,
        :end_date,
      )
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end
    
    def flash_interpolation_options
      { resource_name: 'Service' }
    end
  end
end