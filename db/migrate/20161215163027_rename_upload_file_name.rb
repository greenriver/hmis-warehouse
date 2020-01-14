class RenameUploadFileName < ActiveRecord::Migration[4.2][4.2]
  def change
    rename_column :uploads, :file_name, :file
  end
end
