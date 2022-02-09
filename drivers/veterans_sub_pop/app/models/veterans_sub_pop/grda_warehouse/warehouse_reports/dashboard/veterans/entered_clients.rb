###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteransSubPop::GrdaWarehouse::WarehouseReports::Dashboard::Veterans
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.veterans
    end
  end
end
