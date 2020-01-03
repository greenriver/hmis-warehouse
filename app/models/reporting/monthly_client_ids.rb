###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# A table to hold unique ids for clients involved in monthly reports

module Reporting
  class MonthlyClientIds < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_monthly_client_ids

  end
end