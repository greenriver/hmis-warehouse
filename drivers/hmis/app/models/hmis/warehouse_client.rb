###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::WarehouseClient < GrdaWarehouseBase
  include ArelHelper
  self.table_name = 'warehouse_clients'
  has_paper_trail

  belongs_to :destination, class_name: 'Hmis::Hud::Client', inverse_of: :warehouse_client_destination, optional: true
  belongs_to :source, class_name: 'Hmis::Hud::Client', inverse_of: :warehouse_client_source, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
end
