###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class Episode < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_episodes'
    belongs_to :client, class: 'GrdaWarehouse::Hud::Client'

    has_many :enrollment_links
    has_many :enrollments, through: :enrollment_links
  end
end
