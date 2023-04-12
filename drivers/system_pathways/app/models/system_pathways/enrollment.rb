###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Enrollment < GrdaWarehouseBase
    self.table_name = :system_pathways_enrollments
    acts_as_paranoid

    # Uses a compound key so we can reference a client without needing to know the report.client.id
    belongs_to :client, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]
  end
end
