###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Clients
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active
    def history_scope(scope)
      scope.clients
    end
  end
end
