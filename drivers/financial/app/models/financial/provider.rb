###
# Copyright Green River Data Group, Inc.
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
