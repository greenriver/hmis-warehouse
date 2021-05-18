class CreateClientLocationHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :clh_locations do |t|
      t.references :client, index: true
      t.references :source, polymorphic: true, index: true
      t.date :located_on
      t.float :lat
      t.float :lon
      t.string :collected_by
      t.datetime :processed_at
      t.timestamps
      t.datetime :deleted_at
    end

    add_column :hmis_forms, :location_processed_at, :datetime, index: true
    add_column :hmis_assessments, :with_location_data, :boolean, default: false, null: false, index: true
  end
end
