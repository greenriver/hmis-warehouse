class AddProjectWhitelistColumnToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :project_whitelist, :boolean, default: false
  end
end
