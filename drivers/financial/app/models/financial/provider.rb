###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class Provider < ::GrdaWarehouseBase
    self.table_name = :financial_providers

    has_many :transactions
  end
end
