###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultOnlyHouseholds
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.adult_only_households
    end
  end
end
