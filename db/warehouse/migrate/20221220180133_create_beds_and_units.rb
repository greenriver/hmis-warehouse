class CreateBedsAndUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_units do |t|
      t.references :inventory, null: false, index: true
      t.string :name
      t.timestamps
      t.datetime :deleted_at
      t.string :user_id, null: false
    end

    create_table :hmis_beds do |t|
      t.references :unit, null: false, index: true
      t.string :bed_type, null: false
      t.string :name
      t.string :gender
      t.timestamps
      t.datetime :deleted_at
      t.string :user_id, null: false
    end

    create_table :hmis_active_ranges do |t|
      t.references :entity, polymorphic: true
      t.date :start, null: false
      t.date :end
      t.timestamps
      t.datetime :deleted_at
      t.string :user_id, null: false
    end
  end
end
