###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class Enrollment < GrdaWarehouseBase
    self.table_name = :system_pathways_enrollments
    acts_as_paranoid

    belongs_to :client
  end
end
