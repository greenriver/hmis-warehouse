###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::WarehouseClient < GrdaWarehouseBase
  has_paper_trail
  # acts_as_paranoid

  belongs_to :destination, class_name: 'GrdaWarehouse::Hud::Client',
    inverse_of: :warehouse_client_destination
  belongs_to :source, class_name: 'GrdaWarehouse::Hud::Client',
    inverse_of: :warehouse_client_source

  belongs_to :data_source
  belongs_to :client_match, optional: true
end