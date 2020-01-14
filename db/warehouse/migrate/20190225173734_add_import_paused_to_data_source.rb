class AddImportPausedToDataSource < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :import_paused, :boolean, default: false, null: false
  end
end
