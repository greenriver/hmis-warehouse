class AddFilesListToImports < ActiveRecord::Migration
  def change
    add_column :imports, :unzipped_files, :json
  end
end
