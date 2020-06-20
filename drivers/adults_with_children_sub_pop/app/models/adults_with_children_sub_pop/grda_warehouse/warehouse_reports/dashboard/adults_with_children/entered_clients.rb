###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module AdultsWithChildrenSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildren
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.adults_with_children
    end
  end
end