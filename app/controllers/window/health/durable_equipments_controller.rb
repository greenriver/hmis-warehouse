module Window::Health
  class DurableEquipmentsController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_equipment, only: [:edit, :destroy, :update]

    include PjaxModalController
    include WindowClientPathGenerator
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
      @equipment.update(equipment_params)
      respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
    end
  
    def create
      @button_label = 'Add Equipment Item'
      @form_url = polymorphic_path(health_path_generator + [:durable_equipments], client_id: @client.id)
      @equipment = @patient.equipments.create(equipment_params)
      respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
    end

    def destroy
      @equipment.destroy
      respond_with(@equipment, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
    end

    def equipment_params
      params.require(:health_equipment).permit(
        :item,
        :provider,
        :quantity,
        :effective_date,
        :comments,
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
  end
end