###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Admin::Health
  class RolesController < Admin::RolesController
    include HealthAuthorization
    include HealthPatient
    before_action :require_has_administrative_access_to_health!

    private

    def role_scope
      Role.health
    end

    def role_params
      params.require(:role).
        permit(
          :name,
          Role.health_permissions,
        )
    end
  end
end
