###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Fy2020
  class AprLivingSituation < GrdaWarehouseBase
    self.table_name = 'hud_report_apr_living_situations'

    belongs_to :apr_client, class_name: 'HudApr::Fy2020::AprClient', foreign_key: :hud_report_apr_client_id, inverse_of: :hud_report_apr_living_situations
  end
end
