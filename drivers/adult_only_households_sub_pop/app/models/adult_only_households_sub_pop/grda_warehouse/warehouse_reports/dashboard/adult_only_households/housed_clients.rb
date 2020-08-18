###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module AdultOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultOnlyHouseholds
  class HousedClients < ::GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.adult_only_households
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        adult_only_households.
        open_between(start_date: @start_date, end_date: @end_date)
    end
  end
end