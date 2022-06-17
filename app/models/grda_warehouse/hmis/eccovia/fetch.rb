###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HMIS::Eccovia
  class Fetch < GrdaWarehouseBase
    self.table_name = :eccovia_fetches
    belongs_to :credentials, class_name: 'GrdaWarehouse::RemoteCredentials::Eccovia'

    def fetch_updated
      Assessment.fetch_updated(since: last_fetched_at, data_source_id: data_source_id, credentials: credentials)
    end
  end
end
