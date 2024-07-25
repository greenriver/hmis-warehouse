#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddStaffAssignmentTables < ActiveRecord::Migration[7.0]
  def change
    create_table(:hmis_staff_assignment_types) do |t|
      t.string :name, null: false, comment: 'name of role, such as "Case Manager" or "Housing Navigator"', index: { unique: true }
      t.timestamps
      t.timestamp :deleted_at
    end
    create_table(:hmis_staff_assignments) do |t|
      # This refers to the users table in the app db (not warehouse), so fk relationship is not made explicitly here
      t.references :user, null: false, index: false

      # hmis_households is not actually a table, but a view; the source for HouseholdID is the Enrollments table,
      # which is the reason to not use t.references here.
      t.string :household_id

      t.references :hmis_staff_assignment_type, null: false, foreign_key: { to_table: :hmis_staff_assignment_types }, index: false
      t.references :data_source, null: false
      t.timestamps
      t.timestamp :deleted_at
    end
    add_index :hmis_staff_assignments, [:data_source_id, :household_id, :user_id, :hmis_staff_assignment_type_id], unique: true, where: 'deleted_at IS NULL', name: :uidx_hmis_staff_assignments
    add_index :hmis_staff_assignments, :user_id
  end
end
