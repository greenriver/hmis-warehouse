###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::YouthFamilies
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.youth_families
    end

  end
end