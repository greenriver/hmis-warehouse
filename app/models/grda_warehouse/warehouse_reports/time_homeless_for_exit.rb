###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class TimeHomelessForExit
    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def clients_housed_scope
      GrdaWarehouse::Hud::Client
    end
  end
end
