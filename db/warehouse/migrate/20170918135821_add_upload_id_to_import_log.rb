class AddUploadIdToImportLog < ActiveRecord::Migration[4.2]
  def change
    add_column :import_logs, :upload_id, :integer
  end
end
