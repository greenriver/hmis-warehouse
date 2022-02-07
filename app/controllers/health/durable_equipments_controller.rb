###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class DurableEquipmentsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_equipment, only: [:edit, :destroy, :update]

    def new
      @equipment = equipment_source.new
      @button_label = 'Add Equipment Item'
      @form_url = polymorphic_path(health_path_generator + [:durable_equipments], client_id: @client.id)
    end

    def edit
      @button_label = 'Save Equipment Item'
      @form_url = polymorphic_path(health_path_generator + [:durable_equipment], client_id: @client.id)
    end

    def update
      @button_label = 'Save Equipment Item'
      @form_url = polymorphic_path(health_path_generator + [:durable_equipment], client_id: @client.id)
      @equipment.assign_attributes(equipment_params)
      if request.xhr?
        if @equipment.valid?
          Health::DmeSaver.new(equipment: @equipment, user: current_user).update
        else
          render 'create'
        end
      else
        Health::DmeSaver.new(equipment: @equipment, user: current_user).update
        respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def create
      @button_label = 'Add Equipment Item'
      @form_url = polymorphic_path(health_path_generator + [:durable_equipments], client_id: @client.id)
      @equipment = @patient.equipments.build(equipment_params)
      if request.xhr?
        if @equipment.valid?
          Health::DmeSaver.new(equipment: @equipment, user: current_user).create
        else
          render 'create'
        end
      else
        Health::DmeSaver.new(equipment: @equipment, user: current_user).create
        respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def destroy
      @equipment.destroy
      respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id)) unless request.xhr?
    end

    def equipment_params
      params.require(:health_equipment).permit(
        :item,
        :provider,
        :quantity,
        :effective_date,
        :comments,
        :status,
      )
    end

    def equipment_source
      Health::Equipment
    end

    def set_equipment
      @equipment = equipment_source.find(params[:id].to_i)
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end

    def flash_interpolation_options
      { resource_name: 'Durable Medical Equipment Item' }
    end

    protected def title_for_show
      "#{@client.name} - Health - Durable Medical Equipment"
    end
  end
end
