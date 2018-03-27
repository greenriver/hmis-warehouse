class CreateHudCreateLogs < ActiveRecord::Migration
  def change
    create_table :hud_create_logs do |t|
      t.string :hud_key, null: false
      t.string :type, null: false
      t.datetime :imported_at, null: false, index: true
      t.date :effective_date, null: false, index: true
      t.integer :data_source_id, null: false
    end
  end
end
