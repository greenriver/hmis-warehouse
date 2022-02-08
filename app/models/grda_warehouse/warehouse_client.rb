###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::WarehouseClient < GrdaWarehouseBase
  has_paper_trail
  # acts_as_paranoid

  belongs_to :destination, class_name: 'GrdaWarehouse::Hud::Client',
                           inverse_of: :warehouse_client_destination, optional: true
  belongs_to :source, class_name: 'GrdaWarehouse::Hud::Client',
                      inverse_of: :warehouse_client_source, optional: true

  belongs_to :data_source, optional: true
  belongs_to :client_match, optional: true
end
