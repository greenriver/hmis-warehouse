###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::HudReports
  class ReportClientBase < ReportingBase
    self.abstract_class = true

    has_many :report_clients, as: :universe_membership
  end
end