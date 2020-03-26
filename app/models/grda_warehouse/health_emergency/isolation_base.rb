###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class IsolationBase < GrdaWarehouseBase
    include HealthEmergency
    #self.abstract_class = true
    self.table_name = 'health_emergency_isolations'

    belongs_to :user
    belongs_to :agency
  end
end
