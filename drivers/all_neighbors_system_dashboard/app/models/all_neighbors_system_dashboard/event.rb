###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Event < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :enrollment

    def client_id
      enrollment.source_client.id
    end

    def report_start
      enrollment.start_date
    end

    def report_end
      enrollment.end_date
    end

    def run_date
      enrollment.report.updated_at
    end
  end
end
