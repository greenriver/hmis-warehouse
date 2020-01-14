class AddProjectWhitelistColumnToUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :uploads, :project_whitelist, :boolean, default: false
  end
end
