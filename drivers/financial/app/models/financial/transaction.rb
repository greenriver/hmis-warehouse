###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class Transaction < ::GrdaWarehouseBase
    self.table_name = :financial_transactions

    belongs_to :provider
    belongs_to :client, foreign_key: :external_client_id
  end
end
