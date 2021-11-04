class CreatePmResults < ActiveRecord::Migration[5.2]
  def change
    create_table :pm_results do |t|
      t.references :report, index: true
      t.string :field, null: false, index: true
      t.string :title, null: false
      t.boolean :passed, default: false, null: false
      t.string :direction
      t.integer :primary_value
      t.string :primary_unit
      t.integer :secondary_value
      t.string :secondary_unit
      t.string :value_label
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
