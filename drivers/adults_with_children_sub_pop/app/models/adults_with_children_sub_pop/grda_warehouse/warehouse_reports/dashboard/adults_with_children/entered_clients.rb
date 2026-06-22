###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultsWithChildrenSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildren
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.adults_with_children
    end
  end
end
