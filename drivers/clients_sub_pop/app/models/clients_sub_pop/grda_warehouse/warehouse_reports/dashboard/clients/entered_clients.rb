###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Clients
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.clients
    end
  end
end
