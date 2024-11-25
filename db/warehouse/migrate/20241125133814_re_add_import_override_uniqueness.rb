class ReAddImportOverrideUniqueness < ActiveRecord::Migration[7.0]
  def up
    # Fix incorrect deleted_at limit to allow for duplicates when deleted
    safety_assured do
      execute <<-SQL
        CREATE UNIQUE INDEX uidx_import_overrides_rules
          ON import_overrides (data_source_id, file_name, replaces_column, COALESCE(matched_hud_key, 'ALL'), COALESCE(replaces_value, 'ALL'))
          WHERE deleted_at IS NULL;
      SQL
    end
  end
end
