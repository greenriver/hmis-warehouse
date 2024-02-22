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

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<-SQL
            CREATE UNIQUE INDEX uidx_import_overrides_rules
              ON import_overrides (data_source_id, file_name, replaces_column, COALESCE(matched_hud_key, 'ALL'), COALESCE(replaces_value, 'ALL'))
              WHERE deleted_at IS NOT NULL;
          SQL
        end
      end
    end
  end
end
