###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Financial
  class Provider < ::GrdaWarehouseBase
    self.table_name = :financial_providers

    has_many :transactions
  end
end
