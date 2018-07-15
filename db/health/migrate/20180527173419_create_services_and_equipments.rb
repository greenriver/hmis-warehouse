class CreateServicesAndEquipments < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :service_type
      t.string :provider
      t.string :hours
      t.string :days
      t.date :date_requested
      t.date :effective_date
      t.date :end_date
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :equipment do |t|
      t.string :item
      t.string :provider
      t.integer :quantity
      t.date :effective_date
      t.string :comments
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :careplan_services do |t|
      t.references :careplan
      t.references :service
    end

    create_table :careplan_equipment do |t|
      t.references :careplan
      t.references :equipment
    end
  end
end
