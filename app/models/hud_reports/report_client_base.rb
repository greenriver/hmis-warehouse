###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Base class for a report type's clients.
module HudReports
  class ReportClientBase < GrdaWarehouseBase
    self.abstract_class = true

    has_many :report_clients, as: :universe_membership
  end
end