###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class AdminController < HealthController
    before_action :require_has_administrative_access_to_health!

    def index
    end
  end
end
