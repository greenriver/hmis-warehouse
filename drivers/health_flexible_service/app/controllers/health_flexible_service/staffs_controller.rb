###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class StaffsController < IndividualPatientController
    before_action :set_client

    def update
      @client.update(permitted_params)
    end

    private def permitted_params
      params.require(:grda_warehouse_hud_client).permit(:health_housing_navigator_id)
    end
  end
end
