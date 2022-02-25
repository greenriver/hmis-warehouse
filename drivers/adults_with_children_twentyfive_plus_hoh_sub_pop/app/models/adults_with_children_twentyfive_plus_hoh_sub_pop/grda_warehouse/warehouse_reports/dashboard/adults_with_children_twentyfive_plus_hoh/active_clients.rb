###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenTwentyfivePlusHohSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildrenTwentyfivePlusHoh
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active
    def history_scope(scope)
      scope.adults_with_children_twentyfive_plus_hoh
    end
  end
end
