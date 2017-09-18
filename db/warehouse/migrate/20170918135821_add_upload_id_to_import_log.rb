class AddUploadIdToImportLog < ActiveRecord::Migration
  def change
    add_column :import_logs, :upload_id, :integer
  end
end
