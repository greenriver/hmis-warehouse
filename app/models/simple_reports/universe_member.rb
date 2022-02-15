###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Polymorphic join to connect report cells, to a particular report type's clients
module SimpleReports
  class UniverseMember < GrdaWarehouseBase
    acts_as_paranoid
    self.table_name = 'simple_report_universe_members'
    include RailsDrivers::Extensions

    belongs_to :report_cell, class_name: 'SimpleReports::ReportCell'
    belongs_to :universe_membership, polymorphic: true, inverse_of: :simple_reports_universe_members, optional: true

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  end
end
