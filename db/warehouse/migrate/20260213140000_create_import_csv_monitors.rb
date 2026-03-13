# frozen_string_literal: true

class CreateImportCsvMonitors < ActiveRecord::Migration[7.0]
  def change
    create_table :import_csv_monitors do |t|
      t.references :data_source, null: false, foreign_key: { to_table: :data_sources }
      t.string :csv_file_name, null: false
      t.integer :count_increase_threshold
      t.integer :count_decrease_threshold
      t.integer :min_additions_threshold
      t.integer :max_removals_threshold
      t.boolean :active, null: false, default: true
      t.timestamps
      t.timestamp :deleted_at
    end
  end
end
