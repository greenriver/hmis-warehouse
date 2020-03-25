###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Isolation < GrdaWarehouseBase
    include HealthEmergency

    def status
      return 'In Isolation' if start_date && end_date.blank?
      return "In Isolation until #{end_date}" if start_date

      'Unknown'
    end
  end
end
