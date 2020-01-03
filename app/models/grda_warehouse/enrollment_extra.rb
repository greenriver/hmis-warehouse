###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class EnrollmentExtra < GrdaWarehouseBase
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', inverse_of: :enrollment_extras
  end
end