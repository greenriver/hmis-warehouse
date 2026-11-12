###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientEnrollmentVisibility
  extend ActiveSupport::Concern

  # Condition on "Enrollment"."id"; the relation it's applied to must already join the Enrollment table.
  private def visible_enrollment_condition
    visible_enrollment_ids = GrdaWarehouse::Hud::Enrollment.visible_to(current_user).select(:id)
    GrdaWarehouse::Hud::Enrollment.arel_table[:id].in(visible_enrollment_ids.arel)
  end
end
