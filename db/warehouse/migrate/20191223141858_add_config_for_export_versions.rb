class AddConfigForExportVersions < ActiveRecord::Migration
  def change
    add_column :configs, :only_most_recent_import, :boolean, default: :false
  end
end
