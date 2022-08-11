###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class MyVprsController < HealthController
    before_action :require_can_view_some_vprs!

    def index
      @pagy, @clients = pagy(vpr_patient_scope)
    end

    private def vpr_patient_scope
      scope = ::GrdaWarehouse::Hud::Client.destination.
        where(id: Vpr.active.pluck(:client_id)).
        distinct
      scope = scope.where(health_housing_navigator_id: current_user.id) unless current_user.can_view_all_vprs?
      scope
    end
  end
end
