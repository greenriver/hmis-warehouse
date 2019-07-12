###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.parenting_juvenile
    end
  end
end