###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Project < GrdaWarehouseBase
    self.table_name = :ma_monthly_performance_projects
    acts_as_paranoid
  end
end
