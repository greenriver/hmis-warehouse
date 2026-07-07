###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultOnlyHouseholds
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.adult_only_households
    end
  end
end
