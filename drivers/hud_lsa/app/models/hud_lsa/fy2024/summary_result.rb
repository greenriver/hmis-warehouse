###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Fy2024
  class SummaryResult < ::GrdaWarehouseBase
    include ArelHelper

    belongs_to :lsa, class_name: 'HudLsa::Generators::Fy2024::Lsa', foreign_key: :hud_report_instance_id
  end
end
