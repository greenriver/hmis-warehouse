class AddUnitOccupancy < ActiveRecord::Migration[6.1]
  def change
    remove_column :hmis_units, :inventory_id
    # Units can have a type
    add_column :hmis_units, :unit_type_id, :integer, null: true
    # Units can have a size
    add_column :hmis_units, :unit_size, :integer, null: true

    # Unit records will be used to represent beds
    drop_table :hmis_beds

    # Add table for storing who is assigned to a given unit.
    # active_ranges table is used to store occupancy period.
    create_table :hmis_unit_occupancy do |t|
      t.references :unit, null: false, index: true
      t.references :enrollment, null: false, index: true
      t.references :hmis_service, null: true, index: true
    end
  end
end
