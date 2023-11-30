###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2024
  class BedNight < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_bed_nights'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :enrollment
    belongs_to :episode, optional: true
    belongs_to :service, class_name: 'GrdaWarehouse::Hud::Service', optional: true
  end
end
