###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class IsolationBase < GrdaWarehouseBase
    include ::HealthEmergency
    self.table_name = 'health_emergency_isolations'

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end

    def location_options
      self.class.distinct.
        where.not(location: [nil, '']).
        order(:location).
        pluck(:location)
    end

    def sort_date
      isolation_requested_at || updated_at
    end
  end
end
