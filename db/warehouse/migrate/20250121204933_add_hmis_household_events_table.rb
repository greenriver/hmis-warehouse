#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddHmisHouseholdEventsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :hmis_household_events do |t|
      t.string :HouseholdID, null: false
      t.references :data_source, null: false
      t.string :event_type, null: false
      t.jsonb :event_details
      t.references :user, null: false
      t.timestamps
    end

    add_index :hmis_household_events,
              [:HouseholdID, :data_source_id],
              unique: false,
              name: 'idx_hmis_household_events_on_household_and_data_source'
  end
end
