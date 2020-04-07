###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class IsolationBase < GrdaWarehouseBase
    include ::HealthEmergency
    self.table_name = 'health_emergency_isolations'

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end
  end
end
