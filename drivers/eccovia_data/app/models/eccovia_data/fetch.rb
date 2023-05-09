###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaData
  class Fetch < GrdaWarehouseBase
    self.table_name = :eccovia_fetches
    belongs_to :credentials, class_name: 'EccoviaData::Credential'

    def fetch_updated
      EccoviaData::Assessment.fetch_updated(data_source_id: data_source_id, credentials: credentials)
      EccoviaData::ClientContact.fetch_updated(data_source_id: data_source_id, credentials: credentials)
      EccoviaData::CaseManager.fetch_updated(data_source_id: data_source_id, credentials: credentials)

      update(last_fetched_at: Time.current)
    end
  end
end
