###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::MonthlyPerformance
  class Project < GrdaWarehouseBase
    self.table_name = :ma_monthly_performance_projects
    acts_as_paranoid
  end
end
