###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class InboundApiConfigurationsController < ::ApplicationController
    before_action :require_can_manage_inbound_api_configurations!

    def index
      @confs = HmisExternalApis::InboundApiConfiguration.well_ordered
      @pagy, @confs = pagy(@confs, items: 20)
    end

    def new
      @conf = HmisExternalApis::InboundApiConfiguration.new
    end

    def create
      @conf = HmisExternalApis::InboundApiConfiguration.new(permitted_params)

      if @conf.save
        flash[:alert] = "Your key is #{@conf.plain_text_api_key_with_fallback}. It will be shown below for a short period of time."
        redirect_to action: :index
      else
        flash.now[:alert] = @conf.errors.full_messages
        render :new
      end
    end

    def destroy
      @conf = HmisExternalApis::InboundApiConfiguration.find(params[:id])
      @conf.destroy!
      respond_with(@conf, location: admin_inbound_api_configurations_path)
    end

    private

    def permitted_params
      params
        .require(:hmis_external_apis_inbound_api_configuration)
        .permit(
          :internal_system_id,
          :external_system_name,
        )
    end
  end
end
