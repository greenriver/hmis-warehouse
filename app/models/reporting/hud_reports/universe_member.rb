###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::HudReports
  class UniverseMember < ReportingBase
    self.table_name = 'hud_universe_members'

    belongs_to :report_cell, class_name: 'Reporting::HudReports::ReportCell'
    belongs_to :universe_membership, polymorphic: true
  end
end
