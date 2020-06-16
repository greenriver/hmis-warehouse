###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module YouthParentsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::YouthParents
  class HousedClients < ::GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      # TODO
      GrdaWarehouse::Hud::Client.destination
    end
  end
end