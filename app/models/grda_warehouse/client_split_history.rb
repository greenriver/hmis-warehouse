###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientSplitHistory < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_into, optional: true
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_from, optional: true
  end
end
