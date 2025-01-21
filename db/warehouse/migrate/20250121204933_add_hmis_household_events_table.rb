#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddHmisHouseholdEventsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :hmis_household_events do |t|
      t.string :household_id, index: true # hmis_households is a view, not a table
      t.references :data_source, null: false
      t.string :event_type, null: false
      t.jsonb :event_details
      t.references :user, null: false
      t.timestamps
    end

    # Create a join table since Postgres can't put fk constraints on array elements
    create_table :hmis_household_event_enrollments, id: false do |t|
      t.references :hmis_household_event, null: false, foreign_key: { to_table: :hmis_household_events }, index: { name: 'idx_hmis_household_event_enrollments_on_event_id' }
      t.references :enrollment, null: false, foreign_key: { to_table: :Enrollment }, index: true # this is the ID of the enrollment record: Enrollment.id not Enrollment.EnrollmentID
    end

    # Add a composite unique index to prevent duplicate associations
    add_index :hmis_household_event_enrollments,
              [:hmis_household_event_id, :enrollment_id],
              unique: true,
              name: 'idx_hmis_household_event_enrollments_on_event_and_enrollment'
  end
end
