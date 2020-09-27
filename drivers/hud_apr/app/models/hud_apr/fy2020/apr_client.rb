###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Fy2020
  class AprClient < HudReports::ReportClientBase
    self.table_name = 'hud_report_apr_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership
    has_many :hud_report_apr_living_situations, class_name: 'HudApr::Fy2020::AprLivingSituation', foreign_key: :hud_report_apr_client_id, inverse_of: :apr_client
  end
end
