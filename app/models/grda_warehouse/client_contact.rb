###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientContact < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true
  end
end
