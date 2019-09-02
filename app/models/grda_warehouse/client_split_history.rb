###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class ClientSplitHistory < GrdaWarehouseBase
    belongs_to :destination_client, class_name: GrdaWarehouse::Hud::Client.name, primary_key: :id, foreign_key: :split_into
    belongs_to :source_client, class_name: GrdaWarehouse::Hud::Client.name, primary_key: :id, foreign_key: :split_from
  end
end