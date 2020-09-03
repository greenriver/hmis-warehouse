###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Fy2020
  class AprClient < HudReports::ReportClientBase
    self.table_name = 'hud_report_apr_clients'

    has_many :hud_report_apr_living_situations, class_name: 'HudApr::Fy2020::AprLivingSituation'
  end
end