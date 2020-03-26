###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HealthEmergency
  extend ActiveSupport::Concern

  included do
    def require_health_emergency!
      return true if GrdaWarehouse::Config.get(:health_emergency).present?

      not_authorized!
    end
  end
end
