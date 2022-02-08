###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Polymorphic join to connect report cells, to a particular report type's clients
module HudReports
  class UniverseMember < GrdaWarehouseBase
    acts_as_paranoid
    include RailsDrivers::Extensions

    self.table_name = 'hud_report_universe_members'

    belongs_to :report_cell, class_name: 'HudReports::ReportCell'
    belongs_to :universe_membership, polymorphic: true, inverse_of: :hud_reports_universe_members, optional: true

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  end
end
