###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::HudReports
  class ReportCell < ReportingBase
    self.table_name = 'hud_report_cells'

    belongs_to :report_instance, class_name: 'Reporting::HudReports::ReportInstance'
    has_many :universe_members
  end
end
