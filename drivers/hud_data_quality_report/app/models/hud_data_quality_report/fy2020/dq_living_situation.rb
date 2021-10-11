###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Fy2020
  class DqLivingSituation < GrdaWarehouseBase
    self.table_name = 'hud_report_dq_living_situations'
    acts_as_paranoid

    belongs_to :dq_client, class_name: 'HudDataQualityReport::Fy2020::DqClient', foreign_key: :hud_report_dq_client_id, inverse_of: :hud_report_dq_living_situations, optional: true
  end
end
