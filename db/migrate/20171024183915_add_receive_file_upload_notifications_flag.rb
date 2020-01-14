class AddReceiveFileUploadNotificationsFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :receive_file_upload_notifications, :boolean, default: false
  end
end
