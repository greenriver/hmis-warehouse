###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module NonVeteransSubPop::GrdaWarehouse::WarehouseReports::Dashboard::NonVeterans
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active
    def history_scope(scope)
      scope.non_veterans
    end
  end
end
