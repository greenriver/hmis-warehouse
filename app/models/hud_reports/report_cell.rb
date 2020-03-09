###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# A HUD report cell, identified by a question and cell name (e.g., question: 'Q1', cell_name: 'b2')
module HudReports
  class ReportCell < GrdaWarehouseBase
    self.table_name = 'hud_report_cells'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    has_many :universe_members
  end
end
