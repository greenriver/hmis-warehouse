###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::EtoQaaws
  class ClientLookup < GrdaWarehouseBase
    self.table_name = :eto_client_lookups
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :hmis_client, class_name: 'GrdaWarehouse::HmisClient', primary_key: :client_id, foreign_key: :client_id, optional: true
    has_one :destination_client, through: :client
  end
end
