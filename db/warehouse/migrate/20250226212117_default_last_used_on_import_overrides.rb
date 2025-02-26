class DefaultLastUsedOnImportOverrides < ActiveRecord::Migration[7.0]
  def up
    HmisCsvImporter::ImportOverride.update_all(last_used_on: Date.current)
  end
end
