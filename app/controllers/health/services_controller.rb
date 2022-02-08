###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ServicesController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_service, only: [:edit, :destroy, :update]

    def index
      # For errors in new/edit forms
      @service = service_source.new
      @equipment = Health::Equipment.new
      @services = @patient.services.order(date_requested: :desc)
      @equipments = @patient.equipments
    end

    def new
      @service = service_source.new
      @equipment = Health::Equipment.new
      @button_label = 'Add Service'
      @form_url = polymorphic_path(health_path_generator + [:services], client_id: @client.id)
    end

    def edit
      @button_label = 'Save Service'
      @form_url = polymorphic_path(health_path_generator + [:service], client_id: @client.id)
    end

    def update
      @button_label = 'Save Service'
      @form_url = polymorphic_path(health_path_generator + [:service], client_id: @client.id)
      @service.assign_attributes(service_params)
      if request.xhr?
        if @service.valid?
          Health::ServiceSaver.new(service: @service, user: current_user).update
        else
          render 'create'
        end
      else
        Health::ServiceSaver.new(service: @service, user: current_user).update
        respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def create
      @button_label = 'Add Service'
      @form_url = polymorphic_path(health_path_generator + [:services], client_id: @client.id)
      @service = @patient.services.build(service_params)
      if request.xhr?
        if @service.valid?
          Health::ServiceSaver.new(service: @service, user: current_user).update
        else
          render 'create'
        end
      else
        Health::ServiceSaver.new(service: @service, user: current_user).update
        respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def destroy
      @service.destroy
      respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id)) unless request.xhr?
    end

    def service_params
      params.require(:health_service).permit(
        :service_type,
        :provider,
        :hours,
        :days,
        :date_requested,
        :effective_date,
        :end_date,
        :status,
      )
    end

    def service_source
      Health::Service
    end

    def set_service
      @service = service_source.find(params[:id].to_i)
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

    protected def title_for_show
      "#{@client.name} - Health - Services"
    end
  end
end
