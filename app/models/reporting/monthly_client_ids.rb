###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A table to hold unique ids for clients involved in monthly reports

module Reporting
  class MonthlyClientIds < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_monthly_client_ids

  end
end
