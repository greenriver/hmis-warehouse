###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::HudReports
  class ReportInstance < ReportingBase
    self.table_name = 'hud_report_instances'

    belongs_to :user
    has_many :report_cells
  end
end