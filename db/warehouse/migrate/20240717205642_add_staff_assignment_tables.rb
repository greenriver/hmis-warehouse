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
      # Actually setting the foreign key to the User table caused an exception in rspec when truncating tables from
      # app/models/grda_warehouse/utility.rb. Is it ok to not set up the fk relationship here?
      # similar to t.references :created_by for scan cards and client alerts?
      # t.references :user, null: false, foreign_key: { to_table: :User }, index: false
      t.references :user, null: false, index: false
      t.references :hmis_staff_assignment_type, null: false, foreign_key: { to_table: :hmis_staff_assignment_types }, index: false
      # hmis_households is not actually a table, but a view; the source for HouseholdID is the Enrollments table,
      # which is the reason to not use t.references here.
      t.string :household_id
      t.references :data_source, null: false
      t.timestamps
      t.timestamp :deleted_at
    end
    add_index :hmis_staff_assignments, [:user_id, :hmis_staff_assignment_type_id, :household_id, :data_source_id], unique: true, where: 'deleted_at IS NULL', name: :uidx_hmis_staff_assignments
  end
end
