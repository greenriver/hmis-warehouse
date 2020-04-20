###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.youth_families(start_date: @start_date, end_date: @end_date)
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        youth_families.
        open_between(start_date: @start_date, end_date: @end_date)
    end


  end
end