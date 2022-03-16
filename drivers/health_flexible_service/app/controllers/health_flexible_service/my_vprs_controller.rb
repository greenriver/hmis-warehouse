###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class MyVprsController < HealthController
    before_action :require_can_view_some_vprs!

    def index
      @patients = vpr_patient_scope.
        page(params[:page].to_i).per(25)
    end

    private def vpr_patient_scope
      scope = ::Health::Patient.
        joins(:flexible_services).
        merge(Vpr.active).
        distinct
      scope = scope.where(housing_navigator_id: current_user.id) unless current_user.can_view_all_vprs?
      scope
    end
  end
end
