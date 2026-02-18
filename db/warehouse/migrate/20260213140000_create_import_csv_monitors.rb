# frozen_string_literal: true

class CreateImportCsvMonitors < ActiveRecord::Migration[7.0]
  def change
    create_table :import_csv_monitors do |t|
      t.references :data_source, null: false, foreign_key: { to_table: :data_sources }
      t.string :csv_file_name, null: false
      t.integer :count_increase_threshold
      t.integer :count_decrease_threshold
      t.decimal :percent_increase_threshold, precision: 5, scale: 2
      t.decimal :percent_decrease_threshold, precision: 5, scale: 2
      t.boolean :active, null: false, default: true
      t.timestamps
      t.timestamp :deleted_at

      t.index [:data_source_id, :csv_file_name], unique: true, where: 'deleted_at IS NULL'
    end
  end
end
