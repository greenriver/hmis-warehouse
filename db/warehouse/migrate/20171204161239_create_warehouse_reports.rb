class CreateWarehouseReports < ActiveRecord::Migration
  def change
    create_table :warehouse_reports do |t|
      t.json :parameters
      t.json :data
      t.string :type
      t.datetime "started_at"
      t.datetime "finished_at"

      t.timestamps null: false
    end
  end
end
