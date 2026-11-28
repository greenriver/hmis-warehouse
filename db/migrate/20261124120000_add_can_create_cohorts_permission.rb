###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Adds can_create_cohorts (see Role.permissions_with_descriptions).
#
# can_configure_cohorts is what governed cohort creation before this permission
# existed, so non-system roles holding it are backfilled to keep their access.
class AddCanCreateCohortsPermission < ActiveRecord::Migration[7.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information

    Role.not_system.where(can_configure_cohorts: true).update_all(can_create_cohorts: true)
  end

  def down
    remove_column :roles, :can_create_cohorts
  end
end
