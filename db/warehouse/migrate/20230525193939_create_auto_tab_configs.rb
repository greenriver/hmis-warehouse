class CreateAutoTabConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :cohort_tabs do |t|
      t.references :cohort_id, null: false
      t.string :name
      t.jsonb :rules

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
