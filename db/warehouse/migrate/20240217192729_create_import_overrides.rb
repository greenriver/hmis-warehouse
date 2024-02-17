class CreateImportOverrides < ActiveRecord::Migration[6.1]
  def change
    create_table :import_overrides do |t|
      t.string :file_name, null: false
      t.string :matched_hud_key
      t.string :replaces_column, null: false
      t.string :replaces_value
      t.string :replacement_value, null: false
      t.references :data_source, null: false, foreign_key: true

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
