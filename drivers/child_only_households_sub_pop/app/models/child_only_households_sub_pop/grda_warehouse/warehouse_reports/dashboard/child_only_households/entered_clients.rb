###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ChildOnlyHouseholdsSubPop::GrdaWarehouse::WarehouseReports::Dashboard::ChildOnlyHouseholds
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.child_only_households
    end
  end
end
