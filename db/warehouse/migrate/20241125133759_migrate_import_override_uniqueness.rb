class MigrateImportOverrideUniqueness < ActiveRecord::Migration[7.0]
  def up
    # Update all records to ensure we only have one with a unique data_source_id, file_name, replaces_column, matched_hud_key, replaces_value
    keepers = {}
    HmisCsvImporter::ImportOverride.order(id: :asc).find_each do |row|
      key = [
        row.data_source_id,
        row.file_name,
        row.replaces_column,
        row.matched_hud_key.presence,
        row.replaces_value.presence,
      ]
      keepers[key] ||= row.id
    end
    HmisCsvImporter::ImportOverride.where.not(id: keepers.values).update_all(deleted_at: Time.current)
  end
end
