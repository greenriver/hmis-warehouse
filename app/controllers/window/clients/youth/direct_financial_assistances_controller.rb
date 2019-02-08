module Window::Clients::Youth
  class DirectFinancialAssistancesController < ApplicationController
    include WindowClientPathGenerator
    include PjaxModalController

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!, only: [:create, :destroy]

    before_action :set_client
    before_action :set_entity, only: [:destroy]
    after_action :log_client

    def create
      @entity = entity_source.new(user_id: current_user.id, client_id: @client.id)
      @entity.assign_attributes(entity_params)
      if entity_params[:other].present? && entity_params[:type_provided] == 'Other'
        @entity.type_provided = entity_params[:other]
      end

      @entity.save
      if @entity.valid?
        respond_with(@entity, location: polymorphic_path(youth_intakes_path_generator))
      else
        flash[:error] = "Unable to save #{flash_interpolation_options[:resource_name]}"
        redirect_to polymorphic_path(youth_intakes_path_generator)
      end
    end

    def destroy
      @entity.destroy
      respond_with(@entity, location: polymorphic_path(youth_intakes_path_generator))
    end

    private def entity_params
      params.require(:entity).permit(
        :provided_on,
        :type_provided,
        :other,
      )
    end

    private def set_entity
      @entity = entity_scope.find(params[:id].to_i)
    end

    def set_client
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
    end

    private def entity_source
      GrdaWarehouse::Youth::DirectFinancialAssistance
    end

    private def entity_scope
      entity_source.visible_by?(current_user)
    end

    def flash_interpolation_options
      { resource_name: 'Direct financial assistance' }
    end

  end
end