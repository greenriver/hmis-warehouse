class AddCleanupsToDataSources < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :import_cleanups, :jsonb, default: {}
  end
end
