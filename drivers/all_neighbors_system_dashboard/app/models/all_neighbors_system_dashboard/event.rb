###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Event < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :enrollment

    def report_start
      enrollment.report_start
    end

    def report_end
      enrollment.report_end
    end

    def run_date
      enrollment.report.updated_at
    end
  end
end
