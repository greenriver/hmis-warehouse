###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildrenYouthHoh
  class HousedClients < ::GrdaWarehouse::WarehouseReports::Dashboard::Housed
    def client_source
      GrdaWarehouse::Hud::Client.destination.adults_with_children_youth_hoh
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        adults_with_children_youth_hoh.
        open_between(start_date: @start_date, end_date: @end_date)
    end
  end
end
