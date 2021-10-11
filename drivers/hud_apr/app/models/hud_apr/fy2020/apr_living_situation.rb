###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Fy2020
  class AprLivingSituation < GrdaWarehouseBase
    self.table_name = 'hud_report_apr_living_situations'
    acts_as_paranoid

    belongs_to :apr_client, class_name: 'HudApr::Fy2020::AprClient', foreign_key: :hud_report_apr_client_id, inverse_of: :hud_report_apr_living_situations, optional: true
  end
end
