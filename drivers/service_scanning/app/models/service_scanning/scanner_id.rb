###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ScannerId < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    acts_as_paranoid
  end
end
