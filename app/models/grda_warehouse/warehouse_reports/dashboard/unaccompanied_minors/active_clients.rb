###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::UnaccompaniedMinors
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.unaccompanied_minors
    end
  end
end