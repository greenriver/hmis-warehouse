###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# persist the HUD calculation for chronic homelessness at the enrollment level
# see GrdaWarehouse::ChEnrollment for details
module Hmis
  class ChEnrollment < GrdaWarehouseBase
    self.table_name = 'ch_enrollments'
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment'
  end
end
