class CreatePmCoCStaticSpms < ActiveRecord::Migration[7.0]
  def change
    create_table :pm_coc_static_spms do |t|
      t.references :goal, null: false, index: true
      t.date :report_start, null: false
      t.date :report_end, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
