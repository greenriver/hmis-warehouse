###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class InboundApiConfigurationsController < ::ApplicationController
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
        flash[:alert] = "Your key is #{@conf.plain_text_api_key}. It will not be shown again"
        redirect_to action: :index
      else
        render :new
      end
    end

    def destroy
      @conf = HmisExternalApis::InboundApiConfiguration.find(params[:id])
      @conf.destroy!
      redirect_to action: :index
    end

    private

    def permitted_params
      params
        .require(:hmis_external_apis_inbound_api_configuration)
        .permit(
          :internal_system_name,
          :external_system_name,
        )
    end
  end
end
