###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DeleteHealthOnlyRolesAndReportGroups < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      # Delete user_roles rows first; user_roles.role_id has an FK to roles.id
      # (fk_rails_3369e0d5fc) and must be cleared before the parent roles rows.
      execute('DELETE FROM user_roles WHERE role_id IN (SELECT id FROM roles WHERE health_role = true)')

      # access_controls.role_id/collection_id and access_group_members.access_group_id
      # have no DB-level FK constraints, so these rows would silently orphan
      # (.role/.collection/.access_group returning nil) rather than being caught
      # by the database if left in place after the deletes below.
      execute('DELETE FROM access_controls WHERE role_id IN (SELECT id FROM roles WHERE health_role = true)')
      execute("DELETE FROM access_controls WHERE collection_id IN (SELECT id FROM collections WHERE name = 'All Health Reports')")
      execute("DELETE FROM access_group_members WHERE access_group_id IN (SELECT id FROM access_groups WHERE name = 'All Health Reports')")

      execute('DELETE FROM roles WHERE health_role = true')
      execute("DELETE FROM collections WHERE name = 'All Health Reports'")
      execute("DELETE FROM access_groups WHERE name = 'All Health Reports'")
    end
  end

  def down
    # Irreversible migration, but don't raise on down
  end
end
