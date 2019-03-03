class AddImportPausedToDataSource < ActiveRecord::Migration
  def change
    add_column :data_sources, :import_paused, :boolean, default: false, null: false
  end
end
