class AddFilesListToImports < ActiveRecord::Migration[4.2]
  def change
    add_column :imports, :unzipped_files, :json
  end
end
