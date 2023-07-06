###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class Client < ::GrdaWarehouseBase
    self.table_name = :financial_clients

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
  end
end
