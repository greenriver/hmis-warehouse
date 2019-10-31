class CreateWarehouseAlertsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :warehouse_alerts do |t|
      t.references :user
      t.string :html
      t.timestamps null: false
    end
  end
end
