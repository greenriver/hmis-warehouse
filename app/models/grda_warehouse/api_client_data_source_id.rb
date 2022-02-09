###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ApiClientDataSourceId < GrdaWarehouseBase
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
  alias_attribute :clid, :id_in_data_source
  alias_attribute :site_id, :site_id_in_data_source
  has_one :hmis_client, class_name: 'GrdaWarehouse::HmisClient', primary_key: :client_id, foreign_key: :client_id
  scope :high_priority, -> do
    where temporary_high_priority: true
  end
end
