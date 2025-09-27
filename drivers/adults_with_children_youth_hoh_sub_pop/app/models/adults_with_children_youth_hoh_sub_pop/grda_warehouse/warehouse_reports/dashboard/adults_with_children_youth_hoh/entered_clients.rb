###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::WarehouseReports::Dashboard::AdultsWithChildrenYouthHoh
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered
    def history_scope(scope)
      scope.adults_with_children_youth_hoh
    end
  end
end
