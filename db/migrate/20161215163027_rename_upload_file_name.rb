class RenameUploadFileName < ActiveRecord::Migration
  def change
    rename_column :uploads, :file_name, :file
  end
end
