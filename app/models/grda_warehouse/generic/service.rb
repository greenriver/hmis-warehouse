###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Generic
  class Service < GrdaWarehouseBase
    self.table_name = :generic_services

    belongs_to :client
    belongs_to :data_source
  end
end
