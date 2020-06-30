###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ChildOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::ChildOnlyHouseholds
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.child_only_households
    end
  end
end