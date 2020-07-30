###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientSplitHistory < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_into
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_from
  end
end