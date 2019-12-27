class AddConfigForExportVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :only_most_recent_import, :boolean, default: :false
  end
end
