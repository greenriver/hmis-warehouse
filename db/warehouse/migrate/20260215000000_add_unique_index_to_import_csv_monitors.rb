# frozen_string_literal: true

class AddUniqueIndexToImportCsvMonitors < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_index :import_csv_monitors, [:data_source_id, :csv_file_name], unique: true, name: 'idx_import_csv_monitors_unique_data_source_file'
    end
  end
end
