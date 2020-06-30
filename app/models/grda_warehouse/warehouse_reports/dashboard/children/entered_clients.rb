###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.children_only
    end
  end
end