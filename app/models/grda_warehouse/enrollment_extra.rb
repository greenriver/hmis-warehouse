###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class EnrollmentExtra < GrdaWarehouseBase
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', inverse_of: :enrollment_extras, optional: true
  end
end
