###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class EnrollmentExtra < GrdaWarehouseBase
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', inverse_of: :enrollment_extras, optional: true
  end
end
