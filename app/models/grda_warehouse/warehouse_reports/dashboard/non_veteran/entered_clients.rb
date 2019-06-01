###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.non_veteran
    end

  end
end