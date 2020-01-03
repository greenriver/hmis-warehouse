###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.family
    end

  end
end