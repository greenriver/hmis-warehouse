###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DefaultCohortColumnEditPerm < ActiveRecord::Migration[7.0]
  def up
    Role.where(can_configure_cohorts: true).update_all(can_edit_cohort_columns: true)
  end
end
